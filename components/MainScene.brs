' Copyright (c) 2019 true[X], Inc. All rights reserved.
'----------------------------------------------------------------------------------------------
' MainScene
'----------------------------------------------------------------------------------------------
' Drives UX by coordinating Flow's.
'
' Member Variables:
'   * tarLibrary as ComponentLibrary - used to track the True[X] Component library load status
'   * rootLayout as Node - used as the parent layout for Flow's
'----------------------------------------------------------------------------------------------

'------------------------------------------------------------------------------------------------------
' Begins True[X] ComponentLibrary loading process, ensures global fields are initialized, and presents
' the LoadingFlow to indicate that a (potentially) long running operation is being performed.
'------------------------------------------------------------------------------------------------------
sub init()
    ? "TRUE[X] >>> MainScene::init()"

    ' grab a reference to the root layout node, which will be the parent layout for all nodes
    m.rootLayout = m.top.FindNode("rootLayout")

    ' listen for Truex library load events
    m.tarLibrary = m.top.FindNode("TruexAdRendererLib")
    m.tarLibrary.ObserveField("loadStatus", "onTruexLibraryLoadStatusChanged")

    ' create/set global fields with Channel dimensions (m.global.channelWidth/channelHeight)
    setChannelWidthHeightFromRootScene()

    ' initially present loading screen while Truex library is downloaded and compiled
    showFlow("LoadingFlow")
end sub

'-------------------------------------------------------------------
' Callback triggered by Flow's when their m.top.event field is set.
'
' Supported triggers:
'   * "playButtonSelected" - transition to ContentFlow
'
' Params:
'   * event as roSGNodeEvent - contains the Flow event data
'-------------------------------------------------------------------
sub onFlowEvent(event as Object)
    data = event.GetData()
    if data.trigger = "playButtonSelected" then
        showFlow("ContentFlow")
    else if data.trigger = "cancelStream" then
        showFlow("DetailsFlow")
    else if data.trigger = "streamInfoReceived" then
        ensureGlobalStreamInfoField(data.streamInfo)
        if m.tarLibrary.loadStatus = "ready" or m.tarLibrary.loadStatus = "failed" then showFlow("DetailsFlow")
    end if
end sub

'---------------------------------------------------------------------------------
' Callback triggered when the True[X] ComponentLibrary's loadStatus field is set.
'
' Replaces LoadingFlow with DetailsFlow upon success.
'
' Params:
'   * event as roSGNodeEvent - use event.GetData() to get the loadStatus
'---------------------------------------------------------------------------------
sub onTruexLibraryLoadStatusChanged(event as Object)
    ' make sure tarLibrary has been initialized
    if m.tarLibrary = invalid then return
    ? "TRUE[X] >>>  MainScene::onTruexLibraryLoadStatusChanged(loadStatus=";m.tarLibrary.loadStatus;")"

    ' check the library's loadStatus
    if m.tarLibrary.loadStatus = "none" then
        ? "TRUE[X] >>> TruexAdRendererLib is not currently being downloaded"
    else if m.tarLibrary.loadStatus = "loading" then
        ? "TRUE[X] >>> TruexAdRendererLib is currently being downloaded and compiled"
    else if m.tarLibrary.loadStatus = "ready" then
        ? "TRUE[X] >>> TruexAdRendererLib has been loaded successfully!"

        ' present the DetailsFlow now that the Truex library is ready
        if m.global.streamInfo <> invalid then showFlow("DetailsFlow")
    else if m.tarLibrary.loadStatus = "failed" then
        ? "TRUE[X] >>> TruexAdRendererLib failed to load"

        ' present the DetailsFlow, streams should use standard ads since the Truex library couldn't be loaded
        if m.global.streamInfo <> invalid then showFlow("DetailsFlow")
    else
        ' should not occur
        ? "TRUE[X] >>> TruexAdRendererLib loadStatus unrecognized, ignoring"
    end if
end sub

'----------------------------------------------------------------------------------
' Instantiates and presents a new Flow component of the given name.
'
' The current Flow is not removed until the new Flow is successfully instantiated.
'
' Params:
'   * flowName as String - required; the component name of the new Flow
'----------------------------------------------------------------------------------
sub showFlow(flowName as String)
    ? "TRUE[X] >>> MainScene::showFlow(flowName=";flowName;")"
    ' flowName must be provided
    if flowName = invalid then return

    ' make sure the requested Flow can be instantiated before removing current Flow
    flow = CreateObject("roSGNode", flowName)
    if flow <> invalid then removeCurrentFlow() else return

    ' listen for Flow events on the new flow
    flow.ObserveField("event", "onFlowEvent")

    ' add the new Flow to the layout
    m.rootLayout.AppendChild(flow)

    ' update currentFlow reference and give it focus
    m.currentFlow = flow
    m.currentFlow.SetFocus(true)
end sub

'-----------------------------------------------------------------------
' Clears m.currentFlow's event listener and removes it from the layout.
'
' Does nothing if m.currentFlow is not set.
'-----------------------------------------------------------------------
sub removeCurrentFlow()
    ? "TRUE[X] >>> MainScene::removeCurrentFlow(currentFlow=";m.currentFlow;")"

    if m.currentFlow <> invalid then
        m.currentFlow.UnobserveField("event")
        m.rootLayout.RemoveChild(m.currentFlow)
        m.currentFlow = invalid
    end if
end sub
