# -*-mode: python; py-indent-offset: 4; indent-tabs-mode: nil; encoding: utf-8-dos; coding: utf-8 -*-

import json
import sys
import os
import time

# json was in here
lKNOWN_TOPICS = ['tick', 'timer', 'retval', 'bar', 'cmd', 'eval', 'exec']

# should do something better if there are multiple clients
# deduped
def sMakeMark():
    return "%15.5f" % time.time()

# FixMe:
# The messaging to and from OTMql4Py is still being done with a
# very simple format:
#       sMsgType|sChartId|sIgnored|sMark|sPayload
# where sMsgType is one of: cmd eval (outgoing), timer tick retval (incoming);
#       sChartId is the Mt4 chart sChartId the message is to or from;
#       sMark is a simple floating point timestamp, with milliseconds;
# and   sPayload is command|arg1|arg2... (outgoing) or type|value (incoming),
#       where type is one of: bool int double string json.
# This breaks if the sPayload args or value contain a | -
# we will probably replace this with json or pickled serialization, or kombu.
def sFormatMessage(sMsgType, sChartId, sMark, *lArgs):
    """
    Just a very simple message format for now:
    We are moving over to JSON so *lArgs will be replaced by sJson,
    a single JSON list of [command, arg1, arg2,...]
    """
    # iIgnore is reserved for being a hash on the payload
    iIgnore = 0

    assert sChartId, "ERROR: sChartId is empty"

    if not sMark:
        sMark = sMakeMark()
    sInfo = '|'.join(lArgs)
    sMess = "%s|%s|%d|%s|%s" % (sMsgType, sChartId, iIgnore, sMark, sInfo)
    return sMess

# deduped
def lUnFormatMessage(sBody):
    # FixMe:
    """
    The messaging to and from OTMql4Py is still being done with a
    very simple format:
          sMsgType|sChartId|sIgnored|sMark|sPayload
    where sMsgType is one of: cmd eval (outgoing), timer tick retval (incoming);
          sChartId is the Mt4 chart sChartId the message is to or from;
          sMark is a simple floating point timestamp, with milliseconds;
    and   sPayload is command|arg1|arg2... (outgoing) or type|value (incoming),
          where type is one of: bool int double string json.
    This breaks if the sPayload args or value contain a |
    We will probably replace this with json or pickled serialization, or kombu.
    """
    lArgs = sBody.split('|')
    sCmd = lArgs[0]
    sChart = lArgs[1]
    sIgnore = lArgs[2]
    sMark = lArgs[3]
    return lArgs

class MqlError(RuntimeError):
    pass

def gRetvalToPython(lElts):
    #? raise RuntimeError

    sType = lElts[4]
    if sType == 'string' and len(lElts) <= 5:
        # warn?
        return ""

    if not len(lElts) > 5:
        sys.stdout.write("WARN: nothing to convert in %r\n" % (lElts,))
        return None

    sVal = lElts[5]

    if sType == 'string':
        gRetval = sVal
    elif sType == 'error':
        sys.stdout.write("ERROR:  %s\n" % (sVal,))
        #? should I raise an error?
        # raise RuntimeError()
        return None
    elif sType == 'datetime':
        #? how do I convert this
        # I think it's epoch seconds as an int
        # but what TZ? TZ of the server?
        # I'll treat it as a float like time.time()
        # but probably better to convert it to datetime
        gRetval = float(sVal)
    elif sType == 'bool':
        gRetval = bool(sVal)
    elif sType == 'int':
        gRetval = int(sVal)
    elif sType == 'json':
        gRetval = json.loads(sVal)
    elif sType == 'double':
        gRetval = float(sVal)
    elif sType == 'none':
        gRetval = None
    elif sType == 'void':
        # This is now unused
        gRetval = None
    else:
        sys.stdout.write("WARN: unknown type %s in %r\n" % (sType, lElts,))
        gRetval = None
    return gRetval

