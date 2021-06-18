#[ p2p_bootstrap.nim
 # 
 # Author: Josh Matulenas 
 #
 # Runs the entrance/bootstrap node to the p2p network.
 # Dispatches messages, and encrypts them when necessary.
 #
 # To build: nim c p2p_bootstrap.nim
 ]#
import asyncdispatch, asyncnet, p2p_protocol, monocypher, sysrandom

type
    Peer = ref object
       peer_socket: AsyncSocket
       peer_addr: string
       peer_nick: string
       peer_id: int
       connected: bool
       encrypt: bool
       decrypt: bool
       pubKey: array[0..31, byte]
       privKey: array[0..31, byte]
    
    Peer_server = ref object
        server_socket: AsyncSocket
        peers: seq[Peer]

proc newBootNode(): Peer_server =
    Peer_server(server_socket: newAsyncSocket(), peers: @[])

# Define $ operator to display proc arguments
proc `$`(peer: Peer): string =
    $Peer.peer_id & "(" & peer.peer_addr & ")"

proc parseMessage(peerServer: Peer_server, peer: Peer) {.async.} =
    while true:
       var message = await peer.peer_socket.recvLine()
       if message.len == 0:
           echo(peer, " left the session.")
           peer.connected = false
           peer.peer_socket.close()
           return

       let parsed = protocol(message)
       
       echo(peer, ": ", message)
       for p in peerServer.peers:
           if(("--" & $p.peer_id) == parsed.encrypt):
               message = generateEncryptedMessage(parsed.nickname, parsed.message, parsed.encrypt, cast[seq[byte]](parsed.ciphertext), p.pubKey)
               echo(message) 
               p.decrypt = true

       for p in peerServer.peers:
           if p.peer_id != peer.peer_id and p.connected:
               await p.peer_socket.send(message & "\c\l")       

proc runNode(peerServer: Peer_server, port = 7687) {.async.} =
    peerServer.server_socket.bindAddr(port.Port)
    peerServer.server_socket.listen()

    while true:
        let (peerAddr, peerSocket) = await peerServer.server_socket.acceptAddr()
        echo("Peer @: ", peerAddr, " now connected!")
        let peer = Peer(
            peer_socket: peerSocket,
            peer_addr: peerAddr,
            peer_id: peerServer.peers.len,
            connected: true,
            encrypt: false,
            decrypt: false,
            privKey: getRandomBytes(sizeof(Key)) 
        )
        peer.pubKey = crypto_key_exchange_public_key(peer.privKey) # Need to generate keys here
        peerServer.peers.add(peer)
        await peer.peer_socket.send($peer.peer_id & "\c\l")
        asyncCheck parseMessage(peerServer, peer)
        
      
var newPeer = newBootNode()
waitFor runNode(newPeer)
