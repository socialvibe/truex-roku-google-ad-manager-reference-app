' Copyright (c) 2019 true[X], Inc. All rights reserved.
'-----------------------------------------------------------------------------------------------------------
' ContentFlow
'-----------------------------------------------------------------------------------------------------------
' Uses the IMA SDK to initialize and play a video stream.
'
' Expects m.global.streamInfo to exist with the necessary video stream information.
'
' Member Variables:
'   * videoPlayer as Video - the video player that plays the content stream
'   * streamData as roAssociativeArray - information used by the IMA SDK to request the stream
'   * currentAdBreak as roAssociativeArray - information about the ongoing ad break, provided by ImaSdkTask
'   * adRenderer as TruexAdRenderer - instance of the true[X] renderer, used to present true[X] ads
'-----------------------------------------------------------------------------------------------------------

sub init()
    ? "TRUE[X] >>> ContentFlow::init()"

    if m.global.streamInfo = invalid then return


    ' define the test stream
    jsonStreamInfo = ParseJson(m.global.streamInfo)[0]
    m.streamData = {
        title: jsonStreamInfo.title,
        contentSourceId: jsonStreamInfo.google_content_id,
        videoId: jsonStreamInfo.google_video_id,
        apiKey: "",
        type: "vod"
    }
    ' get reference to video player
    m.videoPlayer = m.top.findNode("videoPlayer")

    ? "TRUE[X] >>> ContentFlow::init() - loading IMA DAI SDK with video streamData=";m.streamData;"..."
    loadImaSdk()
end sub

'-------------------------------------------
' Currently does not handle any key events.
'-------------------------------------------
function onKeyEvent(key as string, press as boolean) as boolean
    ? "TRUE[X] >>> ContentFlow::onKeyEvent(key=";key;"press=";press.ToStr();")"
    return press
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
    m.sdkLoadTask.ObserveFieldScoped("payload", "onPayload")
    m.sdkLoadTask.ObserveField("userCancelStream", "onUserCancelStreamRequested")
    m.sdkLoadTask.streamData = m.streamData
    m.sdkLoadTask.video = m.videoPlayer
    m.sdkLoadTask.control = "run"
end sub

sub onTruexEvent(event as object)
    ? "TRUE[X] >>> ContentFlow::onTruexEvent()"

    data = event.getData()
    if data = invalid then return else ? "TRUE[X] >>> ContentFlow::onTruexEvent(event=";data;")"

    if data.type = "adFreePod" then
        '
        ' [6]
        '

        ' user has earned credit for the engagement, move content past ad break (but don't resume playback)
        m.videoPlayer.seek = m.currentAdBreak.timeOffset + m.currentAdBreak.duration
    else if data.type = "adStarted" then
        m.videoPlayer.control = "pause"
    else if data.type = "adFetchCompleted" then
        ' now the True[X] engagement is ready to start
    else if data.type = "optOut" then
        ' user decided not to engage in True[X] ad, resume playback with default video ads
        m.videoPlayer.control = "play"
    else if data.type = "adCompleted" then
        '
        ' [7]
        '
        ? "TRUE[X] >>> ContentFlow::onTruexEvent() - user requested video stream playback cancel..."

        ' if the user earned credit (via "adFreePod") their content will already be seeked past the ad break
        ' if the user has not earned credit their content will resume at the beginning of the ad break
        m.adRenderer.visible = false
        m.adRenderer.SetFocus(false)
        m.videoPlayer.control = "play"
    else if data.type = "adError" then
        ' there was a problem loading the True[X] ad, resume playback with default video ads
        m.videoPlayer.control = "play"
    else if data.type = "noAdsAvailable" then
        ' there are no True[X] ads available for the user to engage with, resume playback with default video ads
        m.videoPlayer.control = "play"
    else if data.type = "cancelStream" then
        '
        ' [8]
        '
        ? "TRUE[X] >>> ContentFlow::onTruexEvent() - user requested video stream playback cancel..."
        m.top.event = { trigger: "cancelStream" }
    end if
end sub

sub onPayload()
    decodedData = m.sdkLoadTask.payload
    if decodedData = invalid then return
    m.currentAdBreak = decodedData.currentAdBreak
    m.adRenderer = m.top.CreateChild("TruexLibrary:TruexAdRenderer")
    m.adRenderer.observeFieldScoped("event", "onTruexEvent")

    ' use the companion ad data to initialize the True[X] renderer
    ' TODO: remove creativeURL
    m.adRenderer.action = {
        type: "init",
        creativeURL: "temporary creativeURL",
        adParameters: {
            vast_config_url: determineVastConfigUrl(decodedData.vast_config_url, decodedData.user_id),
            placement_hash: decodedData.placement_hash
        },
        supportsCancelStream: true,
        slotType: UCase(getCurrentAdBreakSlotType())
    }
    m.adRenderer.action = { type: "start" }
    m.adRenderer.focusable = true
    m.adRenderer.SetFocus(true)
end sub

'-------------------------------------------------------------------------------------------------------------
' Determines the URL string used to request a VAST config. The full URL is created by appending the following
' URL parameters to the provided baseUrl:
'   * network_user_id = userId, provided
'   * stream_position = either "preroll" or "midroll" depending on ad slot
'   * env[] = appends "brightscript" and "layoutJSON" elements to support Roku
'
' Params:
'   * baseUrl as string - URL of VAST config URL parameters will be appended to
'   * userId as string - identifier used as value for network_user_id URL parameter
'
' Return:
'   full URL to use for VAST config GET request
'-------------------------------------------------------------------------------------------------------------
function determineVastConfigUrl(baseUrl as string, userId as string) as string
    ? "TRUE[X] >>> ContentFlow::determineVastConfigUrl(baseUrl=";baseUrl;", userId=";userId;")"

    ' prepend HTTP protocol if it's absent
    if Left(baseUrl, 4) <> "http" then baseUrl = "https://" + baseUrl

    ' append URL parameters; network_user_id, stream_position, env[]
    baseUrl = baseUrl + "&network_user_id=" + userId
    baseUrl = baseUrl + "&stream_position=" + getCurrentAdBreakSlotType()
    baseUrl = baseUrl + "&env%5B%5D=brightscript"
    baseUrl = baseUrl + "&env%5B%5D=layoutJSON"

    ? "TRUE[X] >>> ContentFlow::determineVastConfigUrl() - URL=";baseUrl
    return baseUrl
end function

'-----------------------------------------------------------------------------------
' Determines the current ad break's (m.currentAdBreak) slot type.
'
' Return:
'   invalid if m.currentAdBreak is not set, otherwise either "midroll" or "preroll"
'-----------------------------------------------------------------------------------
function getCurrentAdBreakSlotType() as dynamic
    if m.currentAdBreak = invalid then return invalid
    if m.currentAdBreak.podindex > 0 then return "midroll" else return "preroll"
end function

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

    ' check for a bookmarked position in the video stream
    if m.sdkLoadTask.bookmark > 0 then
        ? "TRUE[X] >>> ContentFlow::beginStream() - seeking video stream to bookmarked position..."
        m.videoPlayer.seek = m.sdkLoadTask.bookmark
    end if
end sub
