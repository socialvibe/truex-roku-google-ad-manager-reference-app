' Copyright (c) 2019 true[X], Inc. All rights reserved.
'---------------------------------------------------------------------------------------------------------
' LoadingFlow
'---------------------------------------------------------------------------------------------------------
' Simple UI that displays an indeterminate progress indicator (BusySpinner) and short message to indicate
' that a long-running background process is running.
'
' Member Variables:
'   * spinner as BusySpinner - used to indicate background work is being done
'   * fetchStreamTask as FetchStreamInfoTask - background task to retrieve remote video stream info
'---------------------------------------------------------------------------------------------------------

sub init()
    ? "TRUE[X] >>> LoadingFlow::init()"

    ' immediately begin loading the spinner image
    m.spinner = m.top.FindNode("busySpinner")
    m.spinner.poster.uri = m.top.spinnerImageUri
    m.spinner.poster.ObserveField("loadStatus", "onSpinnerLoadStatusChanged")

    fetchStreamInfo()
end sub

'---------------------------------------------------------------------------------
' Checks m.spinner's 'loadStatus', updating UI element positions once it's ready.
'---------------------------------------------------------------------------------
sub onSpinnerLoadStatusChanged()
    if m.spinner = invalid then return
    ? "TRUE[X] >>> LoadingFlow::onSpinnerLoadStatusChanged(loadStatus=";m.spinner.poster.loadStatus;")"
    if m.spinner.poster.loadStatus = "ready" or m.spinner.poster.loadStatus = "failed" then centerLayout()
end sub

'---------------------------------------------------------------------------------
' Checks m.spinner's 'loadStatus', updating UI element positions once it's ready.
'---------------------------------------------------------------------------------
sub onStreamInfo()
    if m.fetchStreamTask.streamInfo <> invalid then
        ? "TRUE[X] >>> LoadingFlow::onStreamInfo() - stream information recevied:";m.fetchStreamTask.streamInfo
        m.top.event = {
            trigger: "streamInfoReceived",
            streamInfo: m.fetchStreamTask.streamInfo
        }
    else
        ? "TRUE[X] >>> LoadingFlow::onStreamInfo() - error fetching stream information..."
        m.top.error = "Failed to fetch stream info."
    end if
end sub

'---------------------------------------------------------------------------------------
' Starts a background task that fetches video stream configuration from known endpoint.
'---------------------------------------------------------------------------------------
sub fetchStreamInfo()
    ? "TRUE[X] >>> LoadingFlow::fetchStreamInfo()"

    if m.fetchStreamTask = invalid then
        m.fetchStreamTask = CreateObject("roSGNode", "FetchStreamInfoTask")
        m.fetchStreamTask.ObserveField("streamInfo", "onStreamInfo")
        m.fetchStreamTask.uri = "https://stash.truex.com/reference-apps/roku/config/reference-app-streams.json"
        m.fetchStreamTask.control = "run"
    end if
end sub

'--------------------------------------------------------------------------------
' Positions UI text elements in the middle of the screen, below the BusySpinner.
'--------------------------------------------------------------------------------
sub centerLayout()
    ? "TRUE[X] >>> LoadingFlow::centerLayout()"

    ' calculate center position for busy spinner based on the Channel resolution
    ' the bitmap's origin is (0, 0), in order to center it correctly we need to account for its width/height
    ' center = (channelWidth|Height / 2) - (bitmapWidth|Height / 2) = (channelWidth|Height - bitmapWidth|Height) / 2
    centerX = (m.global.channelWidth - m.spinner.poster.bitmapWidth) / 2
    centerY = (m.global.channelHeight - m.spinner.poster.bitmapHeight) / 2
    m.spinner.translation = [ centerX, centerY ]
    m.spinner.visible = true

    pleaseWaitLabel = m.top.FindNode("pleaseWait")
    pleaseWaitLabel.width = m.global.channelWidth
    pleaseWaitLabel.height = m.global.channelHeight
    pleaseWaitLabel.translation = [0, (m.spinner.poster.bitmapHeight / 2) + 62]

    loadingLabel = m.top.FindNode("loadingResources")
    loadingLabel.width = m.global.channelWidth
    loadingLabel.height = m.global.channelHeight
    loadingLabel.translation = [0, (m.spinner.poster.bitmapHeight / 2) + 128]
end sub
