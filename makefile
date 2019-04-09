# Copyright (c) 2019 true[X], Inc. All rights reserved.

APPNAME = TruexReferenceApp
IMPORTS =
ROKU_TEST_ID = 1
ROKU_TEST_WAIT_DURATION = 5

ZIP_EXCLUDE = -x *.sh -x makefile -x dist\* -x *app.mk* -x *README* -x *rokuTarget* -x *.svn* -x *.git* -x *.DS_Store* -x out\* -x packages\* -x design\* -x node_modules/**\* -x node_modules -x .buildpath* -x .project* -x renderer\* -x backup\* -x *.code-workspace

APPSROOT = .
include $(APPSROOT)/app.mk
