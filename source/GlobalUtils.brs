' Copyright (c) 2019 true[X], Inc. All rights reserved.
'-----------------------------------------------------
' GlobalUtils
'-----------------------------------------------------
' Some helper functions for updating m.global fields.
'-----------------------------------------------------

'----------------------------------------------------------------------------------------------------------------
' Queries m.top.GetScene().currentDesignResolution to determine the dimensions of the currently running Channel,
' defaulting to 1920x1080 if unavailable. The width and height are then stored in m.global.channelWidth
' and m.global.channelHeight, respectively.
'----------------------------------------------------------------------------------------------------------------
sub setChannelWidthHeightFromRootScene()
    ? "TRUE[X] >>> GlobalUtils::setChannelWidthHeightFromRootScene()"

    ' default to 1920x1080 resolution (fhd)
    channelWidth = 1920
    channelHeight = 1080

    ' overwrite defaults using Scene.currentDesignResolution values, if available
    if m.top.GetScene() <> invalid then designResolution = m.top.GetScene().currentDesignResolution
    if designResolution <> invalid then
        ? "TRUE[X] >>> GlobalUtils::setChannelWidthHeightFromRootScene() - setting from Scene's design resolution..."
        channelWidth = designResolution.width
        channelHeight = designResolution.height
    end if

    ' safely set the m.global channelWidth and channelHeight fields
    ensureGlobalChannelResolutionField(channelWidth, channelHeight)
end sub

'-----------------------------------------------------------------------------------------------------
' Safely sets the channelWidth and channelHeight fields on m.global, adding them if they don't exist.
'
' Params:
'   * width=1920 as integer - value to use for m.global.channelWidth
'   * height=1920 as integer - value to use for m.global.channelHeight
'-----------------------------------------------------------------------------------------------------
sub ensureGlobalChannelResolutionField(width=1920 as integer, height=1080 as integer)
    ? "TRUE[X] >>> GlobalUtils::ensureGlobalChannelResolutionField(width=";width;", height=";height;")"
    if not m.global.HasField("channelWidth") then m.global.AddFields({ channelWidth: width, channelHeight: height })
    m.global.channelWidth = width
    m.global.channelHeight = height
end sub

'------------------------------------------------------------------------------
' Safely sets the streamInfo field on m.global, adding it if it doesn't exist.
'
' Params:
'   * streamInfo="" as string - value to use for m.global.streamInfo
'------------------------------------------------------------------------------
sub ensureGlobalStreamInfoField(streamInfo="" as string)
    ? "TRUE[X] >>> GlobalUtils::ensureGlobalStreamInfoField(streamInfo=";streamInfo;")"
    if not m.global.HasField("streamInfo") then m.global.AddFields({ streamInfo: streamInfo })
    m.global.streamInfo = streamInfo
end sub
