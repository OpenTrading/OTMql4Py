# -*-mode: python; py-indent-offset: 4; tab-width: 8; coding: utf-8-dos -*-

import sys, os, thread, threading

# import rpdb2; rpdb2.start_embedded_debugger('foobar')

# There are/were(2.4) some atexit handlers that were crashing Mt4
# at exit because thay were killing the process, so Mt4 got killed
# when you unloaded the py27.dll. This may not be needed anymore...
import atexit
atexit._exithandlers = atexit._exithandlers[:-1]

# There are/were(2.4) some logging handlers that were polluting Mt4
# at shutdown
import logging
oLOG = logging
def vShutupShutdown(*args, **dArgs): pass
oLOG.shutdown = vShutupShutdown

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
        sys.exc_clear()
        return sRetval
    
    try:
        eval(k, dGlobals, dGlobals)
        if dGlobals['sRetval']:
            sRetval = str(dGlobals['sRetval'])
        else:
            sRetval = ""
    except Exception, e:
        sRetval = "ERROR: Python error evaling " + sPyCode+ ': '+str(e)
        sys.exc_clear()
        return sRetval
    
    if sRetval.find('ERROR:') == 0:
        sys.exc_clear()
    return sRetval


try:
    import win32ui, win32con

    def iMessageBox (sMsg, sTitle, iType, iIcon):
        """
        A frivolity that demonstrates that Mark Hammond's
        win32 code is all callable by Python under Mt4.
        """
        i = win32ui.MessageBox(sMsg, sTitle, iType | iIcon)
        # while != 0 ?
        win32ui.PumpWaitingMessages()
        return i
except ImportError:
    def iMessageBox (sMsg, sTitle, iType, iIcon):
        return -1

# from win32con
MB_OK = 0
MB_OKCANCEL = 1
MB_ABORTRETRYIGNORE = 2
MB_YESNOCANCEL = 3
MB_YESNO = 4
MB_RETRYCANCEL = 5
MB_ICONHAND = 16
MB_ICONQUESTION = 32
MB_ICONEXCLAMATION = 48
MB_ICONASTERISK = 64
MB_ICONWARNING = MB_ICONEXCLAMATION
MB_ICONERROR = MB_ICONHAND
MB_ICONINFORMATION = MB_ICONASTERISK
MB_ICONSTOP = MB_ICONHAND
IDOK = 1
IDCANCEL = 2
IDABORT = 3
IDRETRY = 4
IDIGNORE = 5
IDYES = 6
IDNO = 7
IDCLOSE = 8
IDHELP = 9

lLOG_ARRAY=["CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG", "TRACE"]

def vLog(iLevel, sMsg, *lArgs, **dKeys):
    """
    Level                                Numeric value
    ------                               -----
    CRITICAL                             50
    ERROR                                40
    WARNING                              30
    INFO                                 20
    DEBUG                                10
    NOTSET                               0

From OFLibLogging.mqh:
#define LOG_PANIC 0 // unused
#define LOG_ERROR 1
#define LOG_WARN 2
#define LOG_INFO 3
#define LOG_DEBUG 4
#define LOG_TRACE 5
#define LOG_MAX 5
    """
    import threading, thread
    iId = thread.get_ident()
    try:
        assert 0 <= int(iLevel) <= 5
    except:
        iLevel=4
    try:
        # oLOG.log(50 - iLevel*4, sMsg)
        if iLevel <= 0:
            # oLOG.critical(sMsg, *lArgs, **dKeys)
            print str(iId) + " " +lLOG_ARRAY[iLevel], sMsg
        elif iLevel <= 1:
            # oLOG.error(sMsg, *lArgs, **dKeys)
            print str(iId) + " " +lLOG_ARRAY[iLevel], sMsg
        elif iLevel <= 2:
            # oLOG.warning(sMsg, *lArgs, **dKeys)
            print str(iId) + " " +lLOG_ARRAY[iLevel], sMsg
        elif iLevel <= 3:
            # oLOG.info(sMsg, *lArgs, **dKeys)
            print str(iId) + " " +lLOG_ARRAY[iLevel], sMsg
        else:
            # oLOG.debug(sMsg, *lArgs, **dKeys)
            print str(iId) + " " +lLOG_ARRAY[4], sMsg
        sys.stdout.flush()
        # ValueError when logging to a closed file
    except IOError:
        # [Errno 28] No space left on device - is that IOError?
        # probably filled the disk
        pass
    except Exception, e:
        print str(iId) + " ERROR: in vLog ", str(e), iLevel, sMsg
        sys.exc_clear()

oTKINTER_ROOT = None
sSTDOUT_FD = None

def bStartTkinter():
    """
    Strange but true: you can run Tkinter on Python under Mt4!
    Two event loops, two GUIs; what more could you want.

    We are not planning to take this any further.
    """
    
    global oTKINTER_ROOT, sSTDOUT_FD
    import Tkinter
    if oTKINTER_ROOT is None:
        if not hasattr(sys, 'argv'):
            # __file__
            sys.argv=['py27.py']
        try:
            # should start this in a thread and leave it running?
            oTKINTER_ROOT=Tkinter.Tk()
            oTKINTER_ROOT.withdraw()
        except Exception ,e:
            sShowError('bStartTkinter', "Error starting Tkinter\n%s" % (e,))
            return False

        if True:
            sShowInfo('bStartTkinter', "Started Tkinter")
        else:
            # always pegs to CPU at max
            try:
                import TkFileIO
                # _default_root
                oTop=oTKINTER_ROOT
                frame = TkFileIO.MainFrame(oTop, title ='Python IO')
                oTop.deiconify()
                oTop.tkraise()
                # i=oTop.tk.dooneevent()
                oTop.update()
                sys.stdout=frame.shell
                sys.stderr=frame.shell
                print "INFO: bStartTkinter: Started TkFileIO"
                oTop.update()
            except Exception ,e:
                sShowError('bStartTkinter', "Error starting TkFileIO\n%s" % (e,))
                # return False
        
        return True

    elif oTKINTER_ROOT.__class__ == Tkinter.Tk:
        sShowInfo('bStartTkinter', "Already Started Tkinter")
        return True
    else:
        sShowError('bStartTkinter', "Error starting Tkinter - %s" % (
            oTKINTER_ROOT.__class__,))
        return False        
        
def sShowError(sTitle, sMsg):
    global oTKINTER_ROOT
    if oTKINTER_ROOT:
        import tkMessageBox
        tkMessageBox.showerror(sTitle, sMsg)
    elif sSTDOUT_FD:
        sSTDOUT_FD.write('ERROR : ' + sTitle + ' ' + sMsg + '\n')
        
def sShowInfo(sTitle, sMsg):
    global oTKINTER_ROOT
    if oTKINTER_ROOT is not None:
        import tkMessageBox
        tkMessageBox.showinfo(sTitle, sMsg)
    elif sSTDOUT_FD is not None:
        sSTDOUT_FD.write('INFO : ' + sTitle + ' ' + sMsg + '\n')

def eStartFile(sStdout):
    # idempotent
    global sSTDOUT_FD

    if sStdout == "":
        # setting sStdout = "" means dont log to file
        return ""
    
    if sSTDOUT_FD is None:
        try:
            sStdout=os.path.join(os.path.dirname(__file__), sStdout)
            sSTDOUT_FD = open(sStdout, 'w', 1)
            sys.stdout = sys.stderr = sSTDOUT_FD
            assert sys.stdout != sys.__stdout__

            print sys.version
            sys.stdout.flush()
            assert os.path.isfile(sStdout)
        except Exception, e:
            # may be in trouble logging here if stdout was not opened
            sys.exc_clear()
            return str(e)
        
        try:
            # oLOG.basicConfig(level=logging.DEBUG)
            print "vPyInit - Opened %s %s" % (sSTDOUT_FD.name, sStdout,)
            print "vPyInit - Thread " + threading.currentThread().getName() + \
                  " number " + str(thread.get_ident())
            return ""
        except Exception,e:
            sMsg = "vPyInit - Error opening %s\n%s" % (sStdout, str(e),)
            sys.exc_clear()
            print sMsg
            return sMsg

    elif sSTDOUT_FD:
        # sSTDOUT_FD.seek(0, 0)
        # sSTDOUT_FD.truncate(0)
        return ""
    
def ePyInit(sStdout):
    return eStartFile(sStdout)

def vPyInit(sStdout):
    eStartFile(sStdout)
    # bStartTkinter()

def vPyDeInit():
    global oTKINTER_ROOT, sSTDOUT_FD
    if sSTDOUT_FD:
        try:
            sys.stdout = sys.__stdout__
            sys.stderr = sys.__stderr__
            sName=sSTDOUT_FD.name
            # sShowInfo('vPyDeInit', "Closing %s" % (sName,))
            sSTDOUT_FD.write('INFO : vPyDeInit ' + "Closing outfile %s\n" % (sName,))
            # oLOG.shutdown()
            sSTDOUT_FD.flush()
            sSTDOUT_FD.close()
            sSTDOUT_FD=None
        except Exception,e:
            # You probably have not stdout so no point in logging it!
            print "Error closing %s\n%s" % (sSTDOUT_FD, str(e),)
            sys.exc_clear()
        
    if oTKINTER_ROOT:
        oTKINTER_ROOT.destroy()
        oTKINTER_ROOT=None

    sys.exc_clear()

def test():
    # changing sys.stdout can't be done under doctest
    if os.path.isfile('test.txt'): os.remove('test.txt')

    vPyInit('test.txt')
    assert os.path.isfile('test.txt')

    vPyInit('test.txt')
    assert os.path.isfile('test.txt')
    assert sys.stdout != sys.__stdout__
    assert sys.stderr != sys.__stderr__

    # This can't be done under doctest
    s=sPySafeEval('foobar')
    assert s.find('ERROR:') == 0
    assert s == "ERROR: name 'foobar' is not defined"

    vLog(0, "Level 0")
    vLog(1, "Level 1")
    vLog(2, "Level 2")
    vLog(3, "Level 3")
    vLog(4, "Level 4")

    # oLOG.root.setLevel(40)
    # oLOG.debug("NONONO oLOG.debug")
    # vLog(4, "NONO vLog 4")

    vPyDeInit()
    assert sys.stdout == sys.__stdout__
    assert sys.stderr == sys.__stderr__
    assert oTKINTER_ROOT is None
    assert sSTDOUT_FD is None

    # should check contents of test.txt
    oFd=open('test.txt', 'r')
    sContents=oFd.read()
    oFd.close()
    assert sContents.find("Level 4") > 0
    assert sContents.find("NONO") < 0

def vTestTkinter():
    if False:
        bStartTkinter()
        assert oTKINTER_ROOT
        sShowError('Foo','Bar')

def vTestMessageBox():
    i = iMessageBox("Hi there", "Yes No Cancel",
                    MB_YESNOCANCEL, MB_ICONINFORMATION)
    if i == IDCANCEL:
        pass
    elif i == IDYES:
        pass
    elif i == IDOK:
        pass
    # win32ui.PumpWaitingMessages()

