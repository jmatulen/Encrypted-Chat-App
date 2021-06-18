import os, threadpool, asyncdispatch, asyncnet, p2p_protocol, monocypher, parseutils, strutils

proc connect(peer_sock: AsyncSocket, bootAddr: string) {.async.} = 
    echo("Connecting to chat room: ", bootAddr)
    await peer_sock.connect(bootAddr, 7687.Port)
    echo("Connected to chat room.")

    while true:
        let message = await peer_sock.recvLine()
        let parsed =  protocol(message)
        if peerName == parsed.encrypt:
            echo("Decrypting message from: ", parsed.nickname) 
        echo(parsed.nickname, ": ", parsed.message)

echo("Chat application started!")

# Grab our Bootstrap  node address and peer name from the command line
if paramCount() == 0 or paramCount() > 2:
    quit("To use: Input bootstrap node address! --> ./p2p_client 127.0.0.1 nickname(optional)")

# set bootstrap node address
let serverAddress = paramStr(1)

var peerName = "Anon"
if paramCount() == 2:
    peerName = paramStr(2)

var sock = newAsyncSocket()
asyncCheck connect(sock, serverAddress)
var messageVar = spawn stdin.readLine()

while true:
    if messageVar.isReady():

        var message = generateMessage(peerName, ^messageVar, "hesdf", "")

        asyncCheck sock.send(message)
        messageVar = spawn stdin.readLine()

    asyncdispatch.poll()
