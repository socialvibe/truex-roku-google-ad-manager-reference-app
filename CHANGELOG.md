# Changelog
All notable changes to this project will be documented in this file.

## v1.3.0
* Fixed a bug that caused seek to be 1 second more than needed after playback resume from ad.
* Fixed a bug that caused seek to occur twice when resuming content playback from ad.

## v1.1.2
* Updated to v1 of the TruexAdRenderer (will automatically pick up minor updates from then on)

## v1.1.1
* Fixed `userCancelStream` functionality

## v1.1.0
* Updated to v1.1.0 of the TruexAdRenderer

## v1.0.3
* Updated to v1.0.4 of the TruexAdRenderer
* Updated url manipulation logic for true[X] ad server calls
* Removed TruexAdRenderer dependency for `truex_global_config.json`

## v1.0.2
* Updated to v1.0.3 of the TruexAdRenderer
* fixed a bug that caused the UI to remain hidden when exiting the test stream
