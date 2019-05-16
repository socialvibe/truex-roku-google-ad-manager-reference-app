' Copyright (c) 2019 true[X], Inc. All rights reserved.
'-----------------------------------------------------------------------------
' FetchStreamInfoTask
'-----------------------------------------------------------------------------
' Background task that requests video stream information from a provided URI.
'-----------------------------------------------------------------------------

sub init()
    ? "TRUE[X] >>> FetchStreamInfoTask::init()"
    m.top.functionName = "requestStreamInfo"
end sub

'----------------------------------------------------------------------------------------------------------
' The function to be run on a background thread. Uses the provided URI (m.top.uri) to send an HTTP request
' to get the video stream information.
'
' Upon success the response JSON is parsed into an associative array and assigned to m.top.streamInfo for
' observers to respond. When errors are encountered m.top.error is updated so observers can respond.
'----------------------------------------------------------------------------------------------------------
sub requestStreamInfo()
    ? "TRUE[X] >>> FetchStreamInfoTask::requestStreamInfo()"

    m.port = CreateObject("roMessagePort")
    httpRequest = CreateObject("roUrlTransfer")
    httpRequest.SetPort(m.port)
    httpRequest.setUrl(m.top.uri)
    httpRequest.SetCertificatesFile("common:/certs/ca-bundle.crt")

    ' send the HTTP request and wait up to 5s for response
    if httpRequest.AsyncGetToString() then
        responseCode = 0
        response = ""
        event = Wait(5000, httpRequest.GetPort())
        if Type(event) = "roUrlEvent" then
            responseCode = event.GetResponseCode()
            if responseCode <> 200 then
                m.top.error = "Invalid responseCode=" + responseCode.ToStr()
                return
            end if
            response = event.GetString()
            jsonResponse = ParseJson(response)
            if jsonResponse = invalid then
                m.top.error = "Unrecognized response format, expected JSON object...response=" + response
            else
                ? "TRUE[X] >>> Stream info received, jsonResponse=";jsonResponse
                m.top.streamInfo = response
            end if
        else
            m.top.error = "Unrecognized event returned from AsyncGetToString(), event=" + event
        end if
    else
        m.top.error = "httpRequest.AsyncGetToString() failed"
    end if
end sub
