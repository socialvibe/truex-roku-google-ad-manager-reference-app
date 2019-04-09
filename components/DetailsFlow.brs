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
' TODO: Ideally each 'episode' would start a unique stream.
'
' Member Variables:
'   * playButton as Button - used to begin playing content stream of selected episode
'-------------------------------------------------------------------------------------------------------------

sub init()
    ? "DetailsFlow::init()"

    m.rootLayout = m.top.FindNode("baseFlowLayout")

    m.playButton = m.top.FindNode("playButton")
    m.playButton.ObserveField("buttonSelected", "onPlayButtonSelected")

    m.imagesLoaded = 0
    m.top.FindNode("backgroundImage").ObserveField("loadStatus", "onImageLoaded")
    m.top.FindNode("backgroundImage2").ObserveField("loadStatus", "onImageLoaded")
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
    ? "DetailsFlow::onPlayButtonSelected()"
    m.top.event = {trigger: "playButtonSelected"}
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
    ? "DetailsFlow::onImageLoaded(event=";data;")"
    if data = "ready" or data = "failed" then m.imagesLoaded = m.imagesLoaded + 1
    if m.imagesLoaded > 1 then m.rootLayout.visible = true
end sub

'-----------------------------------------------------------------------
' Determines the next view element to focus from the given direction.
'
' Params:
'   * direction as String - the directional key (on the remote) pressed
'
' Return:
'   true always
'-----------------------------------------------------------------------
function focusElement(direction as String) as Boolean
    m.playButton.SetFocus(not m.playButton.HasFocus())
    return true
end function
