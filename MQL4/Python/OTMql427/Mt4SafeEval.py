# -*-mode: python; py-indent-offset: 4; indent-tabs-mode: nil; encoding: utf-8-dos; coding: utf-8 -*-

import sys, traceback

import logging
oLOG = logging

def sPySafeEval(sPyCode):
    """
    This wraps its string argument in a try:/except:
    so that it always succeeds. If there was an error,
    then the string returned starts with ERROR:
    followed by a description of the error.

    In the caller you should have something like:

      if (StringFind(uRetval, "ERROR:", 0) == 0) {
        Print("Error in Python evaluating: " + uSource + "\n" + res);
        <do something as a result of the failure>
      }

    In fact, you should probably do ALL your calls into Python
    using sPySafeEval unless you know what you are calling
    traps errors, and calls sys.exc_clear() if there is an error.

    """

    dGlobals = sys.modules['__main__'].__dict__
    s = "try:\n    sRetval=" + sPyCode + "\nexcept Exception,e:\n    sRetval='ERROR: '+str(e)"
    try:
        k = compile(s, '<string>', 'exec')
    except Exception, e:
        sRetval = "ERROR: Python error compiling " + sPyCode+ ': '+str(e)
        # sys.stderr.write(sRetval+'\n')
        oLOG.warn(sRetval)
        traceback.print_exc(None, sys.stderr)
        sys.exc_clear()
        return sRetval

    try:
        eval(k, dGlobals, dGlobals)
        if dGlobals['sRetval']:
            sRetval = str(dGlobals['sRetval'])
        else:
            sRetval = ""
    except Exception, e:
        sRetval = "ERROR: Python error evaling " +sPyCode +': ' +str(e)
        # sys.stderr.write(sRetval+'\n')
        oLOG.warn(sRetval)
        traceback.print_exc(None, sys.stderr)
        sys.exc_clear()
        return sRetval

    #? if sRetval.find('ERROR:') == 0: sys.exc_clear()
    
    return sRetval
