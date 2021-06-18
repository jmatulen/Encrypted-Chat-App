#[ p2p_protocol.nim
 # 
 # Author: Josh Matulenas 
 #
 # Builds and Parses Json messages for communication over the network
 #
 # To build: nim c p2p_protocol.nim
 ]#

import json, strutils, parseutils, monocypher, sysrandom, typetraits

type
    # define a public message type
    Message* = object
        nickname*: string
        message*: string
        encrypt*: string
        ciphertext*: seq[byte]
        pubKey*: seq[JsonNode]
        sharedKey*: Key 
        nonce*: Nonce
        mac*: Mac

# Parse Json Messages recieved from peers
proc protocol*(jsonMessage: string): Message =
    # parse our json message
    let parsed = parseJson(jsonMessage)
    var data = to(parsed, Message)
    result.nickname = parsed["nickname"].getStr()
    result.message = parsed["message"].getStr()
    result.encrypt = parsed["encrypt"].getStr()
    result.ciphertext = data.ciphertext
    result.nonce = data.nonce
    result.mac = data.mac
    result.sharedKey = data.sharedKey
    result.pubKey = parsed["pubKey"].getElems()

# Build an encrypted message
proc generateEncryptedMessage*(nickname: string, toEncrypt: string , peerID: string, cipher: seq[byte], #[mac: array[0..15, byte], nonce: array[0..23, byte], sKey: array[0..31, byte],]# pubkey: array[0..31, byte]): string =
    let privateKey = getRandomBytes(sizeof(Key))
    defer: crypto_wipe(privateKey)
    
    let publicKey = crypto_key_exchange_public_key(privateKey)
    let peerPublicKey = pubKey
    let sharedKey = crypto_key_exchange(privateKey, peerPublicKey)
    defer: crypto_wipe(sharedKey)

    let nonce = getRandomBytes(sizeof(Nonce))
    let plaintext = cast[seq[byte]](toEncrypt)
    let (mac, ciphertext) = crypto_lock(sharedKey, nonce, plaintext)

    result = $(%{
        "nickname": %nickname,
        "message": %"ENCRYPTED",
        "encrypt": %peerID,
        "ciphertext": %ciphertext,
        "pubKey": %pubKey,
        "sharedKey": %sharedKey,
        "nonce": %nonce,
        "mac": %mac
     })

# Build Json message for sending to peers
proc generateMessage*(nickname: string, message: string, encrypt: string, cipher: seq[byte], sharedKey: Key, nonce: Nonce, mac: Mac, pubKey: array[0..31, byte]): string =
    var tmp = ""
    if(message.startsWith("--")):
        tmp = message
        tmp.removePrefix("--")
        var parselen = parseUntil(message, tmp, ' ')    

    result = $(%{
        "nickname": %nickname,
        "message": %message,
        "encrypt": %tmp,
        "ciphertext": %cipher,
        "pubKey": %pubKey,
        "sharedKey": %sharedKey,
        "nonce": %nonce,
        "mac": %mac
     
    }) & "\c\l"  #[ add carriage return+linefeed at end
                  # to act as message delimiters
                  ]#
