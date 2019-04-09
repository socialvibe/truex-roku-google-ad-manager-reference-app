# Overview

This project contains sample source code that demonstrates how to integrate true[X]'s Roku
ad renderer with the Google Ad Manager IMA SDK. This document will step through the
various pieces of code that make the integration work, so that the same basic ideas can
be replicated in a real production app.

This reference app covers the essential work. For a more detailed integration guide, please refer to: https://github.com/socialvibe/truex-roku-integrations.

# Assumptions

We assume you have either already integrated the IMA SDK with your app, or you are
working from a project that has been created following the instructions at the
[IMA SDK Quickstart page](https://developers.google.com/interactive-media-ads/docs/sdks/roku/quickstart).

# References

We've marked the source code with comments containing numbers in brackets: (`[3]`, for
example), that correlate with the steps listed below. For example, if you want to see how to parse ad
parameters, search the `ImaSdkTask.brs` file for `[4]` and you will find the related code.

# Steps

## [1] - Keep track of the current ad break

In order to properly control stream behavior around the true[X] engagement experience,
we need to know details about the current ad pod. However, we need to launch the renderer
after receiving information about an ad starting. Therefore, we need to keep track of the
ad break information separately.

In order to accomplish this, we create a field in `ImaSdkTask` called
`currentAdBreak` and we set it in the IMA callback function `adBreakStarted`.

## [2] - Look for true[X] companions for a given ad

In the IMA callback function `onStreamStarted`, we inspect the ad's `companion` property. If
any companion has an `apiFramework` value matching `truex`, then we ignore all other
companions and begin the true[X] engagement experience.

## [3] - Parse ad parameters

The companion object contains a base64 data URL which encodes parameters used
by the true[X] ad renderer. We parse this base64 string into a JSON object.

## [4] - Prepare to enter the engagement

By default the underlying ads, which IMA has stitched into the stream, will keep playing.
First we pause playback. There will be a "placeholder" ad at the
first position of the ad break (this is the true[X] ad also containing information on how to enter the engagement).
We need to seek over the placeholder.

## [5] - Initialize and start the renderer

Once we have the ad parameter JSON object, we can initialize the true[X] ad renderer and listen
for events by observing its `event` field. Once the renderer is done initializing, it will update
its `event` field to an `roAssociativeArray` with a `type: adFetchCompleted` field.

## [6] - Respond to onAdFreePod

If the user fulfills the requirements to earn true[ATTENTION], an event of `type: adFreePod`
will be triggered. We respond by seeking the underlying stream over the
current ad break. This accomplishes the "reward" portion of the engagement.

## [7] - Respond to renderer finish events

There are three ways the renderer can finish:

1. There were no ads available. (`type: noAdsAvailable`)
2. The ad had an error. (`type: adError`)
3. The viewer has completed the engagement. (`type: adCompleted`)

In all three of these cases, the renderer will have removed itself from view.
The remaining work is to resume playback.

## [8] - Respond to stream cancellation

It's possible the viewer will decide to exit the stream while the true[X] engagement
is ongoing. In this case, the renderer will trigger the `type: cancelStream` event.
In a real app, this would likely return to an episode list screen.
