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
    if m.top.GetScene() <> invalid then designResolution = m.top.GetScene().currentDesignResolution

    ' default to 1920x1080 resolution (fhd)
    channelWidth = 1920
    channelHeight = 1080

    ' overwrite defaults if possible
    if designResolution <> invalid then
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
'   * width=1920 as Integer - value to use for m.global.channelWidth
'   * height=1920 as Integer - value to use for m.global.channelHeight
'-----------------------------------------------------------------------------------------------------
sub ensureGlobalChannelResolutionField(width=1920 as Integer, height=1080 as Integer)
    if not m.global.hasField("channelWidth") then m.global.addFields({ channelWidth: width, channelHeight: height })
    m.global.channelWidth = width
    m.global.channelHeight = height
end sub
