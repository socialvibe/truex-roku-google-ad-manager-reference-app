' Copyright (c) 2019 true[X], Inc. All rights reserved.
'---------------------------------------------------------------------------------------------
' ContentFlow
'---------------------------------------------------------------------------------------------
' Uses the IMA SDK to initialize and play the media stream.
'
' Member Variables:
'   * videoPlayer as Video - the video player that plays the content stream
'   * streamData as roAssociativeArray - information streamManager uses to request the stream
'---------------------------------------------------------------------------------------------

sub init()
    ? "ContentFlow::init()"

    m.rootLayout = m.top.FindNode("contentFlowLayout")
    m.videoPlayer = m.top.FindNode("videoPlayer")

    m.streamData = {
        title: "true[X] -- 22 Minute Stream",
        contentSourceId: "2494430",
        videoId: "googleio-highlights",
        apiKey: "",
        type: "vod"
    }

    loadImaSdk()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    ? "ContentFlow::onKeyEvent(key=";key;"press=";press.ToStr();")"
    if not press then return false
    return true
end function

'-----------------------------------------------------------------------
' Called when content stream requests a URL.
'
' Params:
'   * message as Object -
'-----------------------------------------------------------------------
sub onUrlLoadRequested(message as Object)
    ? "ContentFlow::onUrlLoadRequested(data=";FormatJson(message.GetData());")"

    data = message.GetData()
    playStream(data.manifest)
end sub

'-----------------------------------------------------------------------
' Called when an Ad break begins or ends.
'
' Params:
'   * event as Object -
'-----------------------------------------------------------------------
sub onAdBreak(event as Object)
    ? "ContentFlow::onAdBreak()"
    if m.sdkLoadTask.adPlaying then ? "> > > Ad Break Started" else ? "> > > Ad Break Ended"
end sub

'-----------------------------------------------------------------------
' Called when the IMA SDK has finished loading.
'
' Params:
'   * message as Object -
'-----------------------------------------------------------------------
sub onImaSdkLoaded(message as Object)
    ? "ContentFlow::onImaSdkLoaded()"
end sub

'-----------------------------------------------------------------------
' Called when the IMA SDK encounters an error while loading.
'
' Params:
'   * message as Object -
'-----------------------------------------------------------------------
sub onImageSdkLoadError(message as Object)
    ? "ContentFlow::onImageSdkLoadError()"
end sub

'----------------------------------------------------------------------
' Starts the ImaSdkTask task, which loads and initializes the IMA SDK.
'----------------------------------------------------------------------
sub loadImaSdk()
    ? "ContentFlow::loadImaSdk()"

    selectedStream = m.streamData
    m.videoTitle = selectedStream.title

    m.sdkLoadTask = CreateObject("roSGNode", "ImaSdkTask")
    m.sdkLoadTask.ObserveField("sdkLoaded", "onImaSdkLoaded")
    m.sdkLoadTask.ObserveField("errors", "onImageSdkLoadError")
    m.sdkLoadTask.ObserveField("urlData", "onUrlLoadRequested")
    m.sdkLoadTask.ObserveField("adPlaying", "onAdBreak")
    m.sdkLoadTask.streamData = selectedStream
    m.sdkLoadTask.video = m.videoPlayer
    m.sdkLoadTask.control = "run"
end sub

'----------------------------------------------------------------------
' Starts the ImaSdkTask task, which loads and initializes the IMA SDK.
'
' Params:
'   url as String - the URL of the stream to play
'----------------------------------------------------------------------
sub playStream(url as String)
    ? "ContentFlow::playStream(url=";url;")"

    videoContent = CreateObject("roSGNode", "ContentNode")
    videoContent.url = url
    videoContent.title = m.videoTitle
    videoContent.streamFormat = "hls"
    videoContent.playStart = 0

    m.videoPlayer.content = videoContent
    m.videoPlayer.SetFocus(true)
    m.videoPlayer.visible = true
    m.videoPlayer.control = "play"
    m.videoPlayer.EnableCookies()

    if m.sdkLoadTask.bookmark > 0 then m.videoPlayer.seek = m.sdkLoadTask.bookmark
end sub
