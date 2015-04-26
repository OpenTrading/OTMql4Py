# -*-mode: python; py-indent-offset: 4; indent-tabs-mode: nil; encoding: utf-8-dos; coding: utf-8 -*-

"""
A ZmqChart object is a simple abstraction to encapsulate a Mt4 chart
that has a ZeroMQ context on it. There should be only one context for
the whole application, so it is set as the module variable oCONTEXT.

This module can be run from the command line to test Zmq with a listener
such as bin/OTZmqSubscribe.py. Give the message you want to publish
as arguments to this script, or --help to see the options.
"""

import sys, logging
import time
import zmq

oLOG = logging

# There's only one context in zmq
oCONTEXT = None

from Mq4Chart import Mq4Chart

class ZmqChart(Mq4Chart):

    def __init__(self, sSymbol, iPeriod, iIsEA, **dParams):
        global oCONTEXT

        Mq4Chart.__init__(self, sSymbol, iPeriod, iIsEA, dParams)
        if oCONTEXT is None:
            oCONTEXT = zmq.Context()
        self.oSpeakerPubsubSocket = None
        self.oListenerReqrepSocket = None
        self.iSpeakerPort = dParams.get('iSpeakerPort', 0)
        self.iListenerPort = dParams.get('iListenerPort', 0)
        self.sIpAddress = dParams.get('sIpAddress', '127.0.0.1')

    def eBindSpeaker(self):
        """
        We bind on this Metatrader end, and connect from the scripts.
        """
        if self.oSpeakerPubsubSocket is None:
            oSpeakerPubsubSocket = oCONTEXT.socket(zmq.PUB)
            assert self.iSpeakerPort
            oSpeakerPubsubSocket.bind('tcp://%s:%d' % (self.sIpAddress, self.iSpeakerPort,))
            time.sleep(0.1)
            self.oSpeakerPubsubSocket = oSpeakerPubsubSocket

    def eBindListener(self):
        """
        We bind on our Metatrader end, and connect from the scripts.
        """
        if self.oListenerReqrepSocket is None:
            oListenerReqrepSocket = oCONTEXT.socket(zmq.REP)
            assert self.iListenerPort
            oListenerReqrepSocket.bind('tcp://%s:%d' % (self.sIpAddress, self.iListenerPort,))
            time.sleep(0.1)
            self.oListenerReqrepSocket = oListenerReqrepSocket

    def eSendOnSpeaker(self, sTopic, sMsg):
        if self.oSpeakerPubsubSocket is None:
            self.eBindSpeaker()
        assert self.oSpeakerPubsubSocket
        self.oSpeakerPubsubSocket.send_multipart([sTopic, sMsg])
        return ""

    def sRecvOnListener(self):
        if self.oListenerReqrepSocket is None:
            self.eBindListener()
        assert self.oSpeakerPubsubSocket
        # non-blocking
        sRetval = self.oListenerReqrepSocket.recv()
        return sRetval

    def eSendOnListener(self, sMsg):
        if self.oListenerReqrepSocket is None:
            self.eBindListener()
        assert self.oSpeakerPubsubSocket
        self.oListenerReqrepSocket.send(sMsg)
        return ""

    def bCloseContextSockets(self, lOptions):
        global oCONTEXT
        if self.oListenerReqrepSocket:
            self.oListenerReqrepSocket.setsockopt(zmq.LINGER, 0)
            time.sleep(0.1)
            self.oListenerReqrepSocket.close()
        if self.oSpeakerPubsubSocket:
            self.oSpeakerPubsubSocket.setsockopt(zmq.LINGER, 0)
            time.sleep(0.1)
            self.oSpeakerPubsubSocket.close()
        if lOptions and lOptions.iVerbose >= 1:
            print("INFO: destroying the context")
        sys.stdout.flush()
        time.sleep(0.1)
        oCONTEXT.destroy()
        oCONTEXT = None
        return True

def iMain():
    from optparse import OptionParser
    oParser = OptionParser(usage=__doc__.strip())
    oParser.add_option("-p", "--pubport", action="store",
                       dest="sPubPort", type="string",
                       default="2027",
                       help="the TCP port number to publish to (default 2027)")
    oParser.add_option("-a", "--address", action="store",
                       dest="sIpAddress", type="string",
                       default="127.0.0.1",
                       help="the TCP address to subscribe on (default 127.0.0.1)")
    oParser.add_option("-v", "--verbose", action="store",
                       dest="iVerbose", type="string",
                       default="1",
                       help="the verbosity, 0 for silent 4 max (default 1)")
    oParser.add_option("-t", "--topic", action="store",
                       dest="sTopic", type="string",
                       default="retval",
                       help="the topic the subcriber will be lokking for (default retval)")

    (lOptions, lArgs) = oParser.parse_args()

    assert lArgs
    iSpeakerPort = int(lOptions.sPubPort)
    assert iSpeakerPort > 0 and iSpeakerPort < 66000
    sIpAddress = lOptions.sIpAddress
    assert sIpAddress

    try:
        if lOptions.iVerbose >= 1:
            print "Publishing to: " +sIpAddress +":" +str(iSpeakerPort) + \
                " with topic: " +lOptions.sTopic +" ".join(lArgs)
        o = ZmqChart('USDUSD', 0, 0, iSpeakerPort=iSpeakerPort, sIpAddress=sIpAddress)
        sMsg = 'Hello'
        iMax = 10
        i = 0
        print "Sending: %s %d times " % (sMsg, iMax,)
        while i < iMax:
            # send a burst of 10 copies
            o.eSendOnSpeaker(lOptions.sTopic, lArgs[0])
            i += 1
        # print "Waiting for message queues to flush..."
        time.sleep(1.0)
    except KeyboardInterrupt:
        pass
    finally:
        o.bCloseContextSockets(lOptions)

if __name__ == '__main__':
    iMain()
