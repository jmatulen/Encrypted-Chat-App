Peer to Peer Chat App
---------------------
=====================
Joshua Matulenas

Built in the Nim programming language. To build, you will need a Nim compiler.

This application allows users to send messages to each other, while connected to the same chat room.
________
To build
--------
   To build p2p_bootstrap.nim : nim c p2p_bootstrap.nim
   To build p2p_protocol.nim : nim c p2p_protocol.nim
   To build p2p_client.nim : nim c --threads:on p2p_client.nim      

______
To use
------
   1.) run the bootstrap node: ./p2p_bootstrap
   
   2.) run a peer client to connect to the network: ./p2p_client localhost nickname
       note: the nickname is optional
   3.) 
        a.) To send an unencrypted message: type message and enter
        
        b.) To send an encrypted message to a peer: --peerId message to encrypt
                                                   example: user@domain:~/path/to/program$ --1 hello
                                                            This will encrypt "--1 hello" and send it to peer with peer id 1.

            Note: The peer id of the recipient must be known. The list of connected peer Ids 
                  is not known to the user since it isn't displayed. However since we are running all
                  the peers, we know the peer Ids. This would have to be fixed in real life, however for the
                  purpose of the demonstration it will suffice. **This will be remedied soon
   
   4.) To exit the chatroom, enter crtl+c
