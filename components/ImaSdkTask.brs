' Copyright (c) 2019 true[X], Inc. All rights reserved.

' ad libraries provided by the OS
Library "Roku_Ads.brs"
Library "IMA3.brs"

sub init()
    ? "TRUE[X] >>> ImaSdkTask::init()"

    ' set the name of the function to run on background thread
    m.top.functionName = "taskThread"
end sub

sub taskThread()
    ? "TRUE[X] >>> ImaSdkTask::taskThread()"

    ' first, load the IMA SDK
    if not m.top.sdkLoaded then loadImaSdk()

    ' next, setup the content stream
    if not m.top.streamManagerReady then loadStream()

    ' finally, start main loop
    if m.top.streamManagerReady then runLoop()
end sub

sub runLoop()
    ? "TRUE[X] >>> ImaSdkTask::runLoop()"

    m.top.video.timedMetaDataSelectionKeys = ["*"]
    m.port = CreateObject("roMessagePort")

    ' watch all Video player fields
    videoFields = m.top.video.GetFields()
    for each field in videoFields
        m.top.video.ObserveField(field, m.port)
    end for

    while true
        msg = Wait(1000, m.port)
        ' continue running task until video is no longer available
        if m.top.video = invalid then exit while

        m.streamManager.onMessage(msg)

        ' toggle trick play
        m.top.video.enableTrickPlay = m.top.video.position > 3 and not m.top.adPlaying
    end while
    ? "TRUE[X] >>> Exiting ImaSdkTask::runLoop()"
end sub

sub onTruexEvent(event as Object)
    data = event.GetData()
    if data = invalid then return
    ? "TRUE[X] >>> ImaSdkTask::onTruexEvent(event=";data;")"

    if data.type = "adFreePod" then
        '
        ' [6]
        '

        ' user has earned credit for the engagement, move content past ad break (but don't resume playback)
        m.top.video.position = m.top.currentAdBreak.timeOffset + m.top.currentAdBreak.duration
    else if data.type = "adStarted" then
        m.top.video.control = "pause"
    else if data.type = "adFetchCompleted" then
        ' now the True[X] engagement is ready to start
    else if data.type = "optOut" then
        ' user decided not to engage in True[X] ad, resume playback with default video ads
        m.top.video.control = "play"
    else if data.type = "adCompleted" then
        '
        ' [7]
        '

        ' if the user earned credit (via "adFreePod") their content will already be seeked past the ad break
        ' if the user has not earned credit their content will resume at the beginning of the ad break
        m.top.video.control = "play"
    else if data.type = "adError" then
        ' there was a problem loading the True[X] ad, resume playback with default video ads
        m.top.video.control = "play"
    else if data.type = "noAdsAvailable" then
        ' there are no True[X] ads available for the user to engage with, resume playback with default video ads
        m.top.video.control = "play"
    else if data.type = "cancelStream" then
        '
        ' [8]
        '
        m.top.userCancelStream = true
    end if
end sub

    ' adTemplate = {
    '     adbreakinfo: {},
    '     addescription: "string",
    '     adid: "string",
    '     adsystem: "string",
    '     adtitle: "string",
    '     duration: integer,
    '     companions: [],
    '     wrappers: []
    ' }
sub onStreamStarted(ad as Object)
    ? "TRUE[X] >>> ImaSdkTask::onStreamStarted()"

    '
    ' [2]
    '

    ' adCompanionTemplate = {
    '       apiFramework: "string",
    '       creativeType: "string",
    '       height: integer,
    '       width: Integer,
    '       trackingEvents: {object},
    '       url: "data:application/json;base64,[base64-encoded string]"
    ' }
    truexCompanion = getFirstTruexCompanion(ad)
    if truexCompanion <> invalid then
        ? "TRUE[X] >>> True[X] companion detected on ad, companion=";truexCompanion

        '
        ' [3]
        '

        ' grab the base64 part of the "url" field from the companion object
        base64String = Mid(truexCompanion.url, 30).Replace(Chr(10), "")
        ' TODO: are there any other characters we need to replace besides newlines?

        ' construct a JSON object (associative array) from the decoded string
        decodedData = ParseJson(decodeBase64String(base64String))
        ? "TRUE[X] >>> decodedData=";FormatJson(decodedData)
        ' decodedData template = {
        '       user_id: "string",
        '       placement_hash: "string",
        '       vast_config_url: "string"
        ' }

        '
        ' [4]
        '

        ' pause the stream, which is currently playing a video ad
        m.top.video.control = "pause"
        ' seek past the True[X] placeholder video ad
        m.top.video.seek = m.top.video.position + ad.duration

        '
        ' [5]
        '

        ' instantiate the True[X] renderer and register an event listener
        decodedData.currentAdBreak = m.top.currentAdBreak
        m.top.payload = decodedData
    end if
end sub

sub onStreamFirstQuartile(ad as Object)
    ? "TRUE[X] >>> ImaSdkTask::onStreamFirstQuartile()"
end sub

sub onStreamMidpoint(ad as Object)
    ? "TRUE[X] >>> ImaSdkTask::onStreamMidpoint()"
end sub

sub onStreamThirdQuartile(ad as Object)
    ? "TRUE[X] >>> ImaSdkTask::onStreamThirdQuartile()"
end sub

sub onStreamCompleted(ad as Object)
    ? "TRUE[X] >>> ImaSdkTask::onStreamCompleted()"
end sub

sub onStreamError(ad as Object)
    ? "TRUE[X] >>> ImaSdkTask::onStreamError()"
end sub

function determineVastConfigUrl(baseUrl as String, userId as String) as String
    ? "ImaSdkTask::determineVastConfigUrl(baseUrl=";baseUrl;", userId=";userId;")"
    baseUrl = baseUrl + "&network_user_id=" + userId
    if Left(baseUrl, 4) <> "http" then baseUrl = "https://" + baseUrl
    baseUrl = baseUrl + "&stream_position=" + getCurrentAdBreakSlotType()
    baseUrl = baseUrl + "&env%5B%5D=brightscript"
    baseUrl = baseUrl + "&env%5B%5D=layoutJSON"
    ? "VAST_CONFIG_URL=";baseUrl
    return baseUrl
end function

'---------------------------------------------------------------------------------------
' Uses m.top.streamData to initialize and request a content stream through the IMA SDK.
'---------------------------------------------------------------------------------------
sub loadStream()
    ? "TRUE[X] >>> ImaSdkTask::loadStream()"

    m.sdk.initSdk()
    setupVideoPlayer()

    request = m.sdk.CreateStreamRequest()
    if m.top.streamData.type = "live" then
        request.assetKey = m.top.streamData.assetKey
    else
        request.contentSourceId = m.top.streamData.contentSourceId
        request.videoId = m.top.streamData.videoId
    end if
    request.apiKey = m.top.streamData.apiKey
    request.player = m.player

    result = m.sdk.requestStream(request)
    if result <> invalid then
        ? "TRUE[X] >>> ImaSdkTask::loadStream() - error requesting stream - ";result
    else
        m.streamManager = invalid
        while m.streamManager = invalid
            sleep(50)
            m.streamManager = m.sdk.GetStreamManager()
        end while

        if m.streamManager.type <> invalid or m.streamManager.type = "error" then
            errors = CreateObject("roArray", 1, true)
            ? "TRUE[X] >>> ImaSdkTask::loadStream() - error ";m.streamManager.info
            errors.push(m.streamManager.info)
            m.top.errors = errors
        else
            addCallbacks()
            m.top.streamManagerReady = true
            m.streamManager.start()
        end if
    end if
end sub

'----------------------------------------------------------------------------
' Creates and initializes the IMA SDK video player (m.player).
'
' The player requires three anonymous function fields to be set/implemented:
'   * m.player.loadUrl - sets m.top.urlData to given Object
'   * m.player.adBreakStarted - sets m.top.currentAdBreak to given Object
'   * m.player.adBreakEnded - signals that ad break is done
'----------------------------------------------------------------------------
sub setupVideoPlayer()
    ? "TRUE[X] >>> ImaSdkTask::setupVideoPlayer()"

    m.player = m.sdk.CreatePlayer()
    m.player.top = m.top

    m.player.loadUrl = function(urlData)
        ? "TRUE[X] >>> ImaSdkTask::loadUrl(urlData=";urlData;")"
        ' if m.streamManager <> invalid and m.top.streamData.type <> "live" then
        '     m.top.bookmark = m.streamManager.GetStreamTime(m.top.bookmark * 1000)
        ' else
        '     m.top.bookmark = 0
        ' end if
        m.top.video.enableTrickPlay = false
        m.top.urlData = urlData
    end function

    '
    ' [1]
    '
    m.player.adBreakStarted = function(adBreakInfo as Object)
        ? "TRUE[X] >>> ImaSdkTask::adBreakStarted(adBreakInfo=";adBreakInfo;")"
        m.top.currentAdBreak = adBreakInfo
        m.top.adPlaying = true
        m.top.video.enableTrickPlay = false
    end function

    m.player.adBreakEnded = function(adBreakInfo as Object)
        ? "TRUE[X] >>> ImaSdkTask::adBreakEnded(adBreakInfo=";adBreakInfo;")"
        m.top.adPlaying = false
        m.top.video.enableTrickPlay = true
    end function
end sub

'-------------------------------------------------------------------------
' Determines the current ad break's (m.top.currentAdBreak) slot type.
'
' Return:
'   either "midroll" or "preroll", invalid if m.currentAdBreak is not set
'-------------------------------------------------------------------------
function getCurrentAdBreakSlotType() as Dynamic
    if m.top.currentAdBreak = invalid then return invalid
    if m.top.currentAdBreak.podindex > 0 then return "midroll" else return "preroll"
end function

'------------------------------------------------------------------------------------
' Searches ad companions for one that uses the "truex" apiFramework.
'
' Params:
'   * ad as Object - required; the ad information, should contain a companions field
'
' Return:
'   the first companion that uses the "truex" apiFramework, or invalid if none exist
'------------------------------------------------------------------------------------
function getFirstTruexCompanion(ad as Object) as Dynamic
    if ad = invalid or ad.companions = invalid or ad.companions.Count() < 1 then return invalid
    for each companion in ad.companions
        if companion.apiFramework <> invalid and companion.apiFramework = "truex" then return companion
    end for
    return invalid
end function

'------------------------------------------------------------------------------
' Decodes a base64 encoded string into an ASCII string.
'
' Params:
'   * base64String as String - required; the base64 encoded string to decode
'
' Return:
'   the decoded string in ASCII, or an empty string if base64String is invalid
'------------------------------------------------------------------------------
function decodeBase64String(base64String as String) as String
    if base64String = invalid then return ""
    base64ByteArray = CreateObject("roByteArray")
    base64ByteArray.FromBase64String(base64String)
    return base64ByteArray.ToAsciiString()
end function

'------------------------------------------------------------------------------
' Creates an IMA SDK (in m.sdk) and updates m.top.sdkLoaded to reflect status.
'------------------------------------------------------------------------------
sub loadImaSdk()
    ? "TRUE[X] >>> ImaSdkTask::loadImaSdk()"
    if m.sdk = invalid then m.sdk = New_IMASDK()
    m.top.sdkLoaded = true
end sub

'-----------------------------
' Register ad event listeners
'-----------------------------
sub addCallbacks()
    ? "TRUE[X] >>> ImaSdkTask::addCallbacks()"
    m.streamManager.addEventListener(m.sdk.AdEvent.ERROR, onStreamError)
    m.streamManager.addEventListener(m.sdk.AdEvent.START, onStreamStarted)
    m.streamManager.addEventListener(m.sdk.AdEvent.FIRST_QUARTILE, onStreamFirstQuartile)
    m.streamManager.addEventListener(m.sdk.AdEvent.MIDPOINT, onStreamMidpoint)
    m.streamManager.addEventListener(m.sdk.AdEvent.THIRD_QUARTILE, onStreamThirdQuartile)
    m.streamManager.addEventListener(m.sdk.AdEvent.COMPLETE, onStreamCompleted)
end sub
