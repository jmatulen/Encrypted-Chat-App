#[ p2p_client.nim
# The interface to the p2p network
#
# Author: Josh Matulenas
#
# To build: nim c --threads:on p2p_client.nim
# To run: ./p2p_client localhost nickname(optional)
#
# To send non encrypted message: type messages and press enter.  
# To send encrypted message to peer: --peerIdNumber message to encrypt
#                                   example: user@domain:~/dir/to/program$ --1 hello
#                                   This will encrypt "--1 hello" and send it to peer with peerId 1.
#                                   Encrypted messages dont get displayed to the other users, just "ENCRYPTED".
# 
# Note: The peer id of the recipient must be known, but the list of connected peers is not displayed.
#       However we know as we are running them all. For the purpose of the assignment this will suffice.
]#

import os, threadpool, asyncdispatch, asyncnet, p2p_protocol, monocypher, parseutils, strutils, typetraits, sequtils

# Grab our Bootstrap  node address and peer name from the command line
if paramCount() == 0 or paramCount() > 2:
    quit("To use: Input bootstrap node address! --> ./p2p_client 127.0.0.1 nickname(optional)")

# set bootstrap node address
let serverAddress = paramStr(1)

# set peer nickname
var peerName = "Anon"
if paramCount() == 2:
    peerName = paramStr(2)

# connect to peer chatroom
proc connect(peer_sock: AsyncSocket, bootAddr: string) {.async.} = 
    echo("Connecting to chat room: ", bootAddr)
    await peer_sock.connect(bootAddr, 7687.Port)
    let peerId = await peer_sock.recvLine()
    echo("Your assigned Peer ID: ", peerId)
    var id: int
    let pid = parseInt(peerId, id, 0)
    echo("Connected to chat room.")

    # wait for messages, decrypt if necessary
    while true:
        let message = await peer_sock.recvLine()
        let parsed =  protocol(message)
        if (("--" & $id) == parsed.encrypt):
            echo("Decrypting message from: ", parsed.nickname) 
            let decrypted = crypto_unlock((parsed.sharedKey), (parsed.nonce), (parsed.mac), cast[seq[byte]](parsed.ciphertext))
            let intAscii = map(decrypted, proc(x: byte): int = int(x))
            let msgChars = map(intAscii, proc(x: int): char = char(x))
            let msg = msgChars.join("")
            echo("Decrypted message from ",parsed.nickname, ": ", msg)
            continue  

        echo(parsed.nickname, ": ", parsed.message)


var sock = newAsyncSocket()
asyncCheck connect(sock, serverAddress)
var messageVar = spawn stdin.readLine()

# Send messages when we have one to send
while true:
    if messageVar.isReady():
        type
            keyBuffer = array[0..31, byte]
            cipherBuffer = seq[byte]
        var 
            pubKey: keyBuffer
            cipher: cipherBuffer
        
        var sharedKey: Key
        var nonce: Nonce
        var mac: Mac
        
        var message = generateMessage(peerName, ^messageVar, "", cipher, sharedKey, nonce, mac, pubKey)

        asyncCheck sock.send(message)
        messageVar = spawn stdin.readLine()

    asyncdispatch.poll()
