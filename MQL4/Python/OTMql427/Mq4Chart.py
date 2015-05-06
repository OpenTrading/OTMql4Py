# -*-mode: python; py-indent-offset: 4; indent-tabs-mode: nil; encoding: utf-8-dos; coding: utf-8 -*-

"""
A Mq4Chart object is a simple abstraction to encapsulate a Mt4 chart.
"""

import sys, logging

oLOG = logging

# For convenience, define true and false so we can use the MQ4 variables
try:
    __builtins__.true
except AttributeError:
    __builtins__['true'] = True
    __builtins__['false'] = False

def sSafeSymbol(s):
    for elt in ['!', '-', '#', '.']:
        s = s.replace(elt, '')
    return s

class Mq4Chart(object):

    _lCharts = list()
    _dCharts = dict()
    _dChartNames = dict()

    def __init__(self, sChartId, dParams=None):
        self.sChartId = sChartId

        if dParams is None: dParams = dict()
        self.dParams = dParams

        # FixMe: see if it's already there
        self.vAdd(id(self))

    def vAdd(self, iId):
        self.iId = iId
        # see if it's already there
        if iId not in self._dCharts:
            self._lCharts.append(self)
            self._dCharts[iId] = self
            self._dChartNames[self.sChartId] = self

    def vRemove(self, iId):
        if iId in self._dCharts:
            self._lCharts.remove(self)
            del self._dCharts[iId]
            del self._dChartNames[self.sChartId]

    def vReInit(self, **dKeys):
        self.dParams.update(**dKeys)


def oMakeChart(sChartId, dParams):
    """
    Make an instance of a Mq4Chart object to encapsulate a Mt4 chart.
    It will reuse an existing chart or create it needed.
    """
    if sChartId in sys.modules['__main__'].__dict__:
        oLOG.info("Reusing "+sChartId)
        return sys.modules['__main__'].__dict__[sChartId]
    oLOG.info("Creating "+sChartId)
    return Mq4Chart(sChartId, dParams)


def iFindChart(sChartId):
    oLOG.info("Looking for "+sChartId)
    if sChartId in Mq4Chart._dChartNames.keys():
        oLOG.info("Found "+sChartId)
        return Mq4Chart._dChartNames[sChartId].iId
    oLOG.info("Couldn't find "+sChartId+" in "+
              str(Mq4Chart._dChartNames.keys()))
    return 0


def iFindExpert(sSymbol, iPeriod):
    iRetval = -1
    sChartId = "oChart"+"_"+sSafeSymbol(sSymbol) + "_"+str(iPeriod)+"_"
    oLOG.info("Looking for "+sChartId)
    iLen = len(sChartId)
    for sElt in Mq4Chart._dChartNames.keys():
        if sElt.startswith(sChartId):
            iRetval = int(sElt[iLen:])
            if iRetval > 0:
                return iRetval
    oLOG.info("Couldn't find "+sChartId+" in "+
              str(Mq4Chart._dChartNames.keys()))
    return iRetval

def iChartExists(sChartId):
    oLOG.info("Looking for "+sChartId)
    if sChartId in sys.modules['__main__'].__dict__:
        oLOG.info("Found "+sChartId)
        return 1
    oLOG.info("Couldn't find "+sChartId+" in "+
              str(sys.modules['__main__'].__dict__.keys()))
    return 0
