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

    def __init__(self, sSymbol, iPeriod, iIsEA, dParams=None):
        self.sChartName = "oChart"+"_"+sSafeSymbol(sSymbol) + "_"+str(iPeriod)+"_"+str(iIsEA)
        self.sSymbol = sSymbol
        self.iPeriod = iPeriod
        self.iIsEA = iIsEA

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
            self._dChartNames[self.sChartName] = self

    def vRemove(self, iId):
        if iId in self._dCharts:
            self._lCharts.remove(self)
            del self._dCharts[iId]
            del self._dChartNames[self.sChartName]

    def vReInit(self, **dKeys):
        self.dParams.update(**dKeys)


def oMakeChart(sSymbol, iPeriod, iIsEA, dParams):
    """
    Make an instance of a Mq4Chart object to encapsulate a Mt4 chart.
    It will reuse an existing chart or create it needed.
    """
    sChartName = "oChart"+"_"+sSafeSymbol(sSymbol) +"_"+str(iPeriod)+"_"+str(iIsEA)
    if sChartName in sys.modules['__main__'].__dict__:
        oLOG.info("Reusing "+sChartName)
        return sys.modules['__main__'].__dict__[sChartName]
    oLOG.info("Creating "+sChartName)
    return Mq4Chart(sSymbol, iPeriod, iIsEA, dParams)


def iFindChart(sSymbol, iPeriod, iIsEa):
    sChartName = "oChart"+"_"+sSafeSymbol(sSymbol) + "_"+str(iPeriod)+"_"+str(iIsEa)
    oLOG.info("Looking for "+sChartName)
    if sChartName in Mq4Chart._dChartNames.keys():
        oLOG.info("Found "+sChartName)
        return Mq4Chart._dChartNames[sChartName].iId
    oLOG.info("Couldn't find "+sChartName+" in "+
              str(Mq4Chart._dChartNames.keys()))
    return 0


def iFindExpert(sSymbol, iPeriod):
    iRetval = -1
    sChartName = "oChart"+"_"+sSafeSymbol(sSymbol) + "_"+str(iPeriod)+"_"
    oLOG.info("Looking for "+sChartName)
    iLen = len(sChartName)
    for sElt in Mq4Chart._dChartNames.keys():
        if sElt.startswith(sChartName):
            iRetval = int(sElt[iLen:])
            if iRetval > 0:
                return iRetval
    oLOG.info("Couldn't find "+sChartName+" in "+
              str(Mq4Chart._dChartNames.keys()))
    return iRetval

def iChartExists(sSymbol, iPeriod, iExpNumber):
    sChartName = "oChart"+"_"+sSafeSymbol(sSymbol) + "_"+str(iPeriod)+"_"+str(iExpNumber)
    oLOG.info("Looking for "+sChartName)
    if sChartName in sys.modules['__main__'].__dict__:
        oLOG.info("Found "+sChartName)
        return 1
    oLOG.info("Couldn't find "+sChartName+" in "+
              str(sys.modules['__main__'].__dict__.keys()))
    return 0
