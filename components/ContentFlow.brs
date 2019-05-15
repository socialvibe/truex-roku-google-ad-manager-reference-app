' Copyright (c) 2019 true[X], Inc. All rights reserved.
'-----------------------------------------------------------------------------------------------------------
' ContentFlow
'-----------------------------------------------------------------------------------------------------------
' Uses the IMA SDK to initialize and play a video stream with dynamic ad insertion (DAI).
'
' NOTE: Expects m.global.streamInfo to exist with the necessary video stream information.
'
' Member Variables:
'   * videoPlayer as Video - the video player that plays the content stream
'   * streamData as roAssociativeArray - information used by the IMA SDK to request the stream
'   * currentAdBreak as roAssociativeArray - information about the ongoing ad break, provided by ImaSdkTask
'   * sdkLoadTask as ImaSdkTask - relays ad information between Channel and Google's IMA DAI SDK
'   * adRenderer as TruexAdRenderer - instance of the true[X] renderer, used to present true[X] ads
'-----------------------------------------------------------------------------------------------------------

sub init()
    ? "TRUE[X] >>> ContentFlow::init()"

    ' streamInfo must be provided by the global node before instantiating ContentFlow
    if not unpackStreamInformation() then return

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

    ' the manifest field contains the URL of the video stream
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

'------------------------------------------------------------------------------------------------
' Callback triggered when TruexAdRenderer updates its 'event' field.
'
' The following event types are supported:
'   * adFreePod - user has met engagement requirements, skips past remaining pod ads
'   * adStarted - user has started their ad engagement
'   * adFetchCompleted - TruexAdRenderer received ad fetch response
'   * optOut - user has opted out of true[X] engagement, show standard ads
'   * adCompleted - user has finished the true[X] engagement, resume the video stream
'   * adError - TruexAdRenderer encountered an error presenting the ad, resume with standard ads
'   * noAdsAvailable - TruexAdRenderer has no ads ready to present, resume with standard ads
'   * cancelStream - user has requested the video stream be stopped
'
' Params:
'   * event as roAssociativeArray - contains the TruexAdRenderer event data
'------------------------------------------------------------------------------------------------
sub onTruexEvent(event as object)
    ? "TRUE[X] >>> ContentFlow::onTruexEvent()"

    data = event.getData()
    if data = invalid then return else ? "TRUE[X] >>> ContentFlow::onTruexEvent(eventData=";data;")"

    if data.type = "adFreePod" then
        ' this event is triggered when a user has completed all the true[X] engagement criteria
        ' this entails interacting with the true[X] ad and viewing it for X seconds (usually 30s)

        '
        ' [6]
        '

        ' user has earned credit for the engagement, move content past ad break (but don't resume playback)
        m.videoPlayer.seek = m.currentAdBreak.timeOffset + m.currentAdBreak.duration
    else if data.type = "adStarted" then
        ' this event is triggered when a true[X] engagement as started
        ' that means the user was presented with a Choice Card and opted into an interactive ad
        m.videoPlayer.control = "pause"
    else if data.type = "adFetchCompleted" then
        ' this event is triggered when TruexAdRenderer receives a response to an ad fetch request
    else if data.type = "optOut" then
        ' this event is triggered when a user decides not to view a true[X] interactive ad
        ' that means the user was presented with a Choice Card and opted to watch standard video ads
        m.videoPlayer.control = "play"
    else if data.type = "adCompleted" then
        ' this event is triggered when TruexAdRenderer is done presenting the ad

        '
        ' [7]
        '

        ' if the user earned credit (via "adFreePod") their content will already be seeked past the ad break
        ' if the user has not earned credit their content will resume at the beginning of the ad break
        m.adRenderer.visible = false
        m.adRenderer.SetFocus(false)
        m.videoPlayer.control = "play"
    else if data.type = "adError" then
        ' this event is triggered whenever TruexAdRenderer encounters an error
        ' usually this means the video stream should continue with normal video ads
        m.videoPlayer.control = "play"
    else if data.type = "noAdsAvailable" then
        ' this event is triggered when TruexAdRenderer receives no usable true[X] ad in the ad fetch response
        ' usually this means the video stream should continue with normal video ads
        m.videoPlayer.control = "play"
    else if data.type = "cancelStream" then
        ' this event is triggered when the user performs an action interpreted as a request to end the video playback
        ' this event can be disabled by adding supportsUserCancelStream=false to the TruexAdRenderer init payload
        ' there are two circumstances where this occurs:
        '   1. The user was presented with a Choice Card and presses Back
        '   2. The user has earned an adFreePod and presses Back to exit engagement instead of Watch Your Show button

        '
        ' [8]
        '

        ? "TRUE[X] >>> ContentFlow::onTruexEvent() - user requested video stream playback cancel..."
        m.top.event = { trigger: "cancelStream" }
    end if
end sub

'--------------------------------------------------------------------------------------------------------
' Callback triggered when ImaSdbTask updates its 'truexAdData' field. The following fields are expected:
'   * currentAdBreak as roAssociativeArray - current ad break information, including duration
'   * user_id as string - the identifier used as the network_user_id parameter in the VAST config URL
'   * vast_config_url as string - the base URL used to request the VAST config
'   * placement_hash as string - the ad placement's hash value
'
' Params:
'   * event as roAssociativeArray - contains the updated value of ImaSdkTask.truexAdData
'--------------------------------------------------------------------------------------------------------
sub onTruexAdDataReceived(event as object)
    ? "TRUE[X] >>> ContentFlow::onTruexAdDataReceived()"

    decodedData = event.getData()
    if decodedData = invalid then return

    '
    ' [4]
    '
    ? "TRUE[X] >>> ContentFlow::onTruexAdDataReceived() - seeking video position past placeholder ad and pausing..."

    ' pause the stream, which is currently playing a video ad
    m.videoPlayer.control = "pause"
    ' seek past the True[X] placeholder video ad
    m.videoPlayer.seek = m.videoPlayer.position + decodedData.currentAdBreak.duration
    m.currentAdBreak = decodedData.currentAdBreak

    '
    ' [5]
    '
    ? "TRUE[X] >>> ContentFlow::onTruexAdDataReceived() - instantiating TruexAdRenderer ComponentLibrary..."

    ' instantiate TruexAdRenderer and register for event updates
    m.adRenderer = m.top.createChild("TruexLibrary:TruexAdRenderer")
    m.adRenderer.observeFieldScoped("event", "onTruexEvent")

    ' use the companion ad data to initialize the true[X] renderer
    tarInitAction = {
        type: "init",
        adParameters: {
            vast_config_url: determineVastConfigUrl(decodedData.vast_config_url, decodedData.user_id),
            placement_hash: decodedData.placement_hash
        },
        supportsCancelStream: true, ' enables cancelStream event types, disable if Channel does not support
        slotType: UCase(getCurrentAdBreakSlotType())
    }
    ? "TRUE[X] >>> ContentFlow::onTruexAdDataReceived() - initializing TruexAdRenderer with action=";tarInitAction
    m.adRenderer.action = tarInitAction

    ? "TRUE[X] >>> ContentFlow::onTruexAdDataReceived() - starting TruexAdRenderer..."
    m.adRenderer.action = { type: "start" }
    m.adRenderer.focusable = true
    m.adRenderer.SetFocus(true)
end sub

'----------------------------------------------------------------------------------
' Constructs m.streamData from stream information provided at m.global.streamInfo.
'
' Return:
'   false if there was an error unpacking m.global.streamInfo, otherwise true
'----------------------------------------------------------------------------------
function unpackStreamInformation() as boolean
    if m.global.streamInfo = invalid then
        ? "TRUE[X] >>> ContentFlow::unpackStreamInformation() - invalid m.global.streamInfo, must be provided..."
        return false
    end if

    ' extract stream info JSON into associative array
    ? "TRUE[X] >>> ContentFlow::unpackStreamInformation() - parsing m.global.streamInfo=";m.global.streamInfo;"..."
    jsonStreamInfo = ParseJson(m.global.streamInfo)[0]
    if jsonStreamInfo = invalid then
        ? "TRUE[X] >>> ContentFlow::unpackStreamInformation() - could not parse streamInfo as JSON, aborting..."
        return false
    end if

    ' define the test stream
    m.streamData = {
        title: jsonStreamInfo.title,
        contentSourceId: jsonStreamInfo.google_content_id,
        videoId: jsonStreamInfo.google_video_id,
        apiKey: "",
        type: "vod"
    }
    ? "TRUE[X] >>> ContentFlow::unpackStreamInformation() - streamData=";m.streamData

    return true
end function

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
'----------------------------------------------------------------------
sub loadImaSdk()
    ? "TRUE[X] >>> ContentFlow::loadImaSdk()"

    m.sdkLoadTask = createObject("roSGNode", "ImaSdkTask")
    m.sdkLoadTask.observeField("sdkLoaded", "onImaSdkLoaded")
    m.sdkLoadTask.observeField("errors", "onSdkLoadErrors")
    m.sdkLoadTask.observeField("urlData", "onUrlLoadRequested")
    m.sdkLoadTask.observeField("adPlaying", "onAdBreak")
    m.sdkLoadTask.observeFieldScoped("truexAdData", "onTruexAdDataReceived")
    m.sdkLoadTask.observeField("userCancelStream", "onUserCancelStreamRequested")
    m.sdkLoadTask.streamData = m.streamData
    m.sdkLoadTask.video = m.videoPlayer
    m.sdkLoadTask.control = "run"
end sub

'-----------------------------------------------------------------------------
' Creates a ContentNode with the provided URL and starts the video player.
' 
' If the IMA task has a bookmarked position the video stream will seek to it.
'
' Params:
'   url as string - the URL of the stream to play
'-----------------------------------------------------------------------------
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
