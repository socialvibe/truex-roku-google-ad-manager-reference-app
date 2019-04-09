' Copyright (c) 2019 true[X], Inc. All rights reserved.
'---------------------------------------------------------------------------------------------
' ContentFlow
'---------------------------------------------------------------------------------------------
' Uses the IMA SDK to initialize and play a media stream.
'
' Member Variables:
'   * videoPlayer as Video - the video player that plays the content stream
'   * streamData as roAssociativeArray - information streamManager uses to request the stream
'---------------------------------------------------------------------------------------------

sub init()
    ? "ContentFlow::init()"

    m.videoPlayer = m.top.FindNode("videoPlayer")

    ' define the test stream
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

'------------------------------------------------------------------------------------------------------------
' Called when content stream requests a URL to be loaded. The 'manifest' field of the new value of 'urlData'
' is used to point the video player to a new content stream.
'
' Params:
'   * event as roAssociativeArray - should contain a 'manifest' field
'------------------------------------------------------------------------------------------------------------
sub onUrlLoadRequested(event as Object)
    data = event.GetData()
    if data = invalid then return else ? "ContentFlow::onUrlLoadRequested(data=";FormatJson(data);")"

    ' verify that 'manifest' exists on 'data' before updating the video stream
    if data.DoesExist("manifest") then playStream(data.manifest) else ? "No manifest field, ignoring urlData update."
end sub

'--------------------------------------------------------------------------------------------------------
' Triggered when m.sdkLoadTask.adPlaying gets updated. This signals the beginning or end of an ad break.
'
' Params:
'   * event as roAssociativeArray - contains the new (Boolean) value of m.sdkLoadTask.adPlaying
'--------------------------------------------------------------------------------------------------------
sub onAdBreak(event as Object)
    data = event.GetData()
    ? "ContentFlow::onAdBreak(adPlaying=";data;")"
    if data <> invalid and data = true then ? "> > > Ad Break Started" else ? "> > > Ad Break Ended"
end sub

'-----------------------------------------------------------------------------------------------
' Called when the IMA SDK has finished loading.
'
' Params:
'   * event as roAssociativeArray - contains the new (Boolean) value of m.sdkLoadTask.sdkLoaded
'-----------------------------------------------------------------------------------------------
sub onImaSdkLoaded(event as Object)
    data = event.GetData()
    ? "ContentFlow::onImaSdkLoaded(sdkLoaded=";data;")"
end sub

'----------------------------------------------------------------------
' Called when the IMA SDK encounters an error(s) while loading.
'
' Params:
'   * event as roAssociativeArray - contains an array of error strings
'----------------------------------------------------------------------
sub onSdkLoadErrors(event as Object)
    data = event.GetData()
    ? "ContentFlow::onSdkLoadErrors(errors=";data;")"
    ' TODO: recover?
end sub

'------------------------------------------------------------------------------------
' Called when the user intends to cancel the media stream.
'
' Params:
'   * event as roAssociativeArray - contains value of m.sdkLoadTask.userCancelStream
'------------------------------------------------------------------------------------
sub onUserCancelStreamRequested(event as Object)
    data = event.GetData()
    ? "ContentFlow::onUserCancelStreamRequested(cancelStream=";data;")"
    m.top.event = { trigger: "cancelStream" }
end sub

'----------------------------------------------------------------------
' Starts the ImaSdkTask task, which loads and initializes the IMA SDK.
'----------------------------------------------------------------------
sub loadImaSdk()
    ? "ContentFlow::loadImaSdk()"

    m.sdkLoadTask = CreateObject("roSGNode", "ImaSdkTask")
    m.sdkLoadTask.ObserveField("sdkLoaded", "onImaSdkLoaded")
    m.sdkLoadTask.ObserveField("errors", "onSdkLoadErrors")
    m.sdkLoadTask.ObserveField("urlData", "onUrlLoadRequested")
    m.sdkLoadTask.ObserveField("adPlaying", "onAdBreak")
    m.sdkLoadTask.ObserveField("userCancelStream", "onUserCancelStreamRequested")
    m.sdkLoadTask.streamData = m.streamData
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
    videoContent.title = m.streamData.title
    videoContent.streamFormat = "hls"
    videoContent.playStart = 0

    m.videoPlayer.content = videoContent
    m.videoPlayer.SetFocus(true)
    m.videoPlayer.visible = true
    m.videoPlayer.control = "play"
    m.videoPlayer.EnableCookies()

    if m.sdkLoadTask.bookmark > 0 then m.videoPlayer.seek = m.sdkLoadTask.bookmark
end sub
