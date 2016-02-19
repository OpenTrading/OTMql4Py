# -*-mode: python; fill-column: 75; tab-width: 8; coding: utf-8; encoding: utf-8-dos -*-
# $Id$
# Copyright:
# Licence:

OT_LOG_PANIC=0 # unused
OT_LOG_ERROR=1
OT_LOG_WARN=2
OT_LOG_INFO=3
OT_LOG_DEBUG=3
OT_LOG_TRACE=4

def vLog(iLevel, *lMess):
    print ' '.join(lMess)

def vError(*gMess):
  vLog(OT_LOG_ERROR, "ERROR: ", *gMess)

def vWarn(*gMess):
  vLog(OT_LOG_WARN, "WARN: ", *gMess)

def vInfo(*gMess):
  vLog(OT_LOG_INFO, "INFO: ", *gMess)

def vDebug(*gMess):
  vLog(OT_LOG_DEBUG, "DEBUG: ", *gMess)

def vTrace(*gMess):
  vLog(OT_LOG_TRACE, "TRACE: ", *gMess)
