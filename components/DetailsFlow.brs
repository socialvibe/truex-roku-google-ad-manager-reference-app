' Copyright (c) 2019 true[X], Inc. All rights reserved.
'-------------------------------------------------------------------------------------------------------------
' DetailsFlow
'-------------------------------------------------------------------------------------------------------------
' Sample TV show-esque details screen. The intent is to simulate common video streaming app (Netflix, etc...)
' user flow. Users can select an 'episode' from a carousel list to start the content stream.
'
' The layout contains: a title text field for the 'TV show', a short description of the 'show', a list of
' 'episodes' to choose from, and a Play button.
'
' Member Variables:
'   * playButton as Button - used to begin playing content stream of selected episode
'-------------------------------------------------------------------------------------------------------------

sub init()
    ? "TRUE[X] >>> DetailsFlow::init()"

    m.rootLayout = m.top.FindNode("baseFlowLayout")

    m.playButton = m.top.FindNode("playButton")
    m.playButton.ObserveField("buttonSelected", "onPlayButtonSelected")

    m.numImagesLoading = 0
    bgPoster = m.top.FindNode("backgroundImage")
    if bgPoster.loadStatus = "loading" then
        bgPoster.ObserveField("loadStatus", "onImageLoaded")
        m.numImagesLoading += 1
    end if
    bgPoster2 = m.top.FindNode("backgroundImage")
    if bgPoster2.loadStatus = "loading" then
        bgPoster2.ObserveField("loadStatus", "onImageLoaded")
        m.numImagesLoading += 1
    end if

    if m.numImagesLoading = 0 then m.top.visible = true

    if m.global.streamInfo = invalid then return
    streamInfo = ParseJson(m.global.streamInfo)[0]
    streamTitle = streamInfo.title
    if streamTitle <> invalid then m.top.FindNode("detailsFlowTitle").text = streamTitle
    streamDesc = streamInfo.description
    if streamDesc <> invalid then m.top.FindNode("detailsFlowDescription").text = streamDesc
    streamCover = streamInfo.cover
    if streamCover <> invalid then m.top.FindNode("episode1").uri = streamCover
    if m.numImagesLoading <= 0 then m.rootLayout.visible = true
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "left" or key = "right" or key = "up" or key = "down" then return focusElement(key)
    return false
end function

'--------------------------------------------------------------------------------------------------
' Callback triggered when Play button is selected. Starts the stream by signaling via m.top.event.
'--------------------------------------------------------------------------------------------------
sub onPlayButtonSelected()
    ? "TRUE[X] >>> DetailsFlow::onPlayButtonSelected()"
    m.top.event = { trigger: "playButtonSelected", details: "TODO: pass selected content data" }
end sub

'------------------------------------------------------------------------------------------------------------------
' Callback triggered when a Poster's loadStatus gets updated. Toggles the root layout's visibility when all images
' have loaded (or failed to load).
'
' Params:
'   * event as roSGNodeEvent - contains the image loadStatus value
'------------------------------------------------------------------------------------------------------------------
sub onImageLoaded(event as Object)
    data = event.GetData()
    ? "TRUE[X] >>> DetailsFlow::onImageLoaded(event=";data;")"
    if data <> "loading" then m.numImagesLoading -= 1
    if m.numImagesLoading = 0 then m.rootLayout.visible = true
end sub

'-----------------------------------------------------------------------
' Determines the next view element to focus from the given direction.
'
' Params:
'   * direction as string - the directional key (on the remote) pressed
'
' Return:
'   true always
'-----------------------------------------------------------------------
function focusElement(direction as string) as boolean
    playButtonFocus = m.playButton.HasFocus()
    m.rootLayout.SetFocus(true)
    m.playButton.SetFocus(not playButtonFocus)
    return true
end function
