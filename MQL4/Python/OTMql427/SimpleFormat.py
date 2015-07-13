# -*-mode: python; py-indent-offset: 4; indent-tabs-mode: nil; encoding: utf-8-dos; coding: utf-8 -*-

# json was in here
lKNOWN_TOPICS = ['tick', 'timer', 'retval', 'bar', 'cmd', 'eval', 'exec']

def sFormatMessage(sMsgType, sChartId, sMark, sType, sValue):
    # FixMe: the sMess must be in the right format
    iIgnore = 0
    if not sMark:
        sMark = "%15.5f" % time.time()
    sMess = "%s|%s|%d|%s|%s|%s" % (sMsgType, sChartId, iIgnore, sMark, sType, sValue,)
    return sMess

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

