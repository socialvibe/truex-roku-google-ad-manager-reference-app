' Copyright (c) 2019 true[X], Inc. All rights reserved.

'--------------------------------------------------------------------------------------------------------------------
' Entry point for the reference Channel.
'
' Performs the usual initial setup for a SceneGraph Channel; sets up the Screen with a MessagePort then instantiates
' and presents MainScene, listening on the message port until the Screen is closed.
'--------------------------------------------------------------------------------------------------------------------
sub Main()
    ? "TAR-Roku-Reference::Main()"

    ' create the host Screen object and attach message port to listen for events
    m.port = CreateObject("roMessagePort")
    screen = CreateObject("roSGScreen")
    screen.SetMessagePort(m.port)

    ' create and display the main scene of this reference Channel
    scene = screen.CreateScene("MainScene")
    screen.Show()

    ' continuously monitor screen messages until it's closed
    while true
        msg = Wait(0, m.port)
        msgType = Type(msg)
        ? "TAR-Roku-Reference - Main event loop message received; msgType=";msgType

        if msgType <> "roSGScreenEvent" and msg.isScreenClosed() then return
    end while
end sub
