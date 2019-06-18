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
    if m.top.getScene() <> invalid then designResolution = m.top.getScene().currentDesignResolution
    if designResolution <> invalid then
        ? "TRUE[X] >>> GlobalUtils::setChannelWidthHeightFromRootScene() - setting from Scene's design resolution..."
        channelWidth = designResolution.width
        channelHeight = designResolution.height
    end if

    ' safely set the m.global channelWidth and channelHeight fields
    setGlobalField("channelWidth", channelWidth)
    setGlobalField("channelHeight", channelHeight)
end sub

'---------------------------------------------------------------------------------------------------------
' Safely sets the value of a field in m.global, adding it explicitly (via addFields) if it doesn't exist.
'
' Params:
'   * fieldName as string - name of the field that will take the fieldValue
'   * fieldValue as dynamic - value of the global field, use invalid to remove a field
'---------------------------------------------------------------------------------------------------------
sub setGlobalField(fieldName as string, fieldValue as dynamic)
    ? "TRUE[X] >>> GlobalUtils::setGlobalField(fieldName=";fieldName;", fieldValue=";fieldValue;")"

    if not m.global.hasField(fieldName) then
        ? "TRUE[X] >>> GlobalUtils::setGlobalField() - adding ";fieldName;" to m.global..."
        newField = {}
        newField[fieldName] = fieldValue
        m.global.addFields(newField)
    else
        ? "TRUE[X] >>> GlobalUtils::setGlobalField() - updating existing field (";fieldName;") in m.global..."
    end if
end sub
