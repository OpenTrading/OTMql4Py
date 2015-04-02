# -*-mode: python; fill-column: 75; tab-width: 8; coding: utf-8-dos -*-

import sys, os, thread, threading

# import rpdb2; rpdb2.start_embedded_debugger('foobar')
    
import atexit
import logging
oLOG=logging
atexit._exithandlers=atexit._exithandlers[:-1]
def vShutupShutdown(*args, **dArgs): pass
oLOG.shutdown=vShutupShutdown

def sPySafeEval(sPyCode):
    dGlobals=sys.modules['__main__'].__dict__
    s = "try:\n    sRetval=" + sPyCode + "\nexcept Exception,e:\n    sRetval='ERROR: '+str(e)"
    try:
        k = compile(s, '<string>', 'exec')
    except Exception, e:
        sRetval="ERROR: Python error compiling " + sPyCode+ ': '+str(e)
        sys.exc_clear()
        return sRetval
    
    try:
        eval(k, dGlobals, dGlobals)
        if dGlobals['sRetval']:
            sRetval=str(dGlobals['sRetval'])
        else:
            sRetval=""
    except Exception, e:
        sRetval="ERROR: Python error evaling " + sPyCode+ ': '+str(e)
        sys.exc_clear()
        return sRetval
    
    if sRetval.find('ERROR:') == 0:
        sys.exc_clear()
    return sRetval



try:
    import win32ui, win32con

    def iMessageBox (sMsg, sTitle, iType, iIcon):
        i=win32ui.MessageBox(sMsg, sTitle, iType | iIcon)
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
    iId=thread.get_ident()
    lLogArray=["CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG", "TRACE"]
    try:
        assert 0 <= int(iLevel) <= 5
    except:
        iLevel=4
    try:
        # oLOG.log(50 - iLevel*4, sMsg)
        if iLevel <= 0:
            # oLOG.critical(sMsg, *lArgs, **dKeys)
            print str(iId) + " " +lLogArray[iLevel], sMsg
        elif iLevel <= 1:
            # oLOG.error(sMsg, *lArgs, **dKeys)
            print str(iId) + " " +lLogArray[iLevel], sMsg
        elif iLevel <= 2:
            # oLOG.warning(sMsg, *lArgs, **dKeys)
            print str(iId) + " " +lLogArray[iLevel], sMsg
        elif iLevel <= 3:
            # oLOG.info(sMsg, *lArgs, **dKeys)
            print str(iId) + " " +lLogArray[iLevel], sMsg
        else:
            # oLOG.debug(sMsg, *lArgs, **dKeys)
            print str(iId) + " " +lLogArray[4], sMsg
        sys.stdout.flush()
        # ValueError when logging to a closed file
    except IOError:
        # [Errno 28] No space left on device - is that IOError?
        # probably filled the disk
        pass
    except Exception, e:
        print str(iId) + " ERROR: in vLog ", str(e), iLevel, sMsg
        sys.exc_clear()
        pass

__root__=None
__outfile__=None

def bStartTkinter():
    global __root__, __outfile__
    import Tkinter
    if __root__ is None:
        if not hasattr(sys, 'argv'):
            # __file__
            sys.argv=['py27.py']
        try:
            # should start this in a thread and leave it running?
            __root__=Tkinter.Tk()
            __root__.withdraw()
        except Exception ,e:
            sShowError('bStartTkinter', "Error starting Tkinter\n%s" % (e,))
            return False

        if 1:
            sShowInfo('bStartTkinter', "Started Tkinter")
        else:
            # always pegs to CPU at max
            try:
                import TkFileIO
                # _default_root
                oTop=__root__
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

    elif __root__.__class__ == Tkinter.Tk:
        sShowInfo('bStartTkinter', "Already Started Tkinter")
        return True
    else:
        sShowError('bStartTkinter', "Error starting Tkinter - %s" % (
            __root__.__class__,))
        return False        
        
def sShowError(sTitle, sMsg):
    global __root__
    if __root__:
        import tkMessageBox
        tkMessageBox.showerror(sTitle, sMsg)
    elif __outfile__:
        __outfile__.write('ERROR : ' + sTitle + ' ' + sMsg + '\n')
        
def sShowInfo(sTitle, sMsg):
    global __root__
    if __root__ is not None:
        import tkMessageBox
        tkMessageBox.showinfo(sTitle, sMsg)
    elif __outfile__ is not None:
        __outfile__.write('INFO : ' + sTitle + ' ' + sMsg + '\n')

def bStartFile(sStdout):
    global __outfile__

    # __outfile__ is None:
    if sStdout == "":
        pass
    elif not __outfile__:
        try:
            sStdout=os.path.join(os.path.dirname(__file__), sStdout)
            __outfile__ = open(sStdout, 'w', 1)
            sys.stdout = sys.stderr = __outfile__
            assert sys.stdout != sys.__stdout__

            print sys.version
            sys.stdout.flush()
            assert os.path.isfile(sStdout)
        except Exception, e:
            # may be in trouble logging here if stdout was not opened
            sys.exc_clear()
            return False
        
        try:
            # oLOG.basicConfig(level=logging.DEBUG)
            print "vPyInit - Opened %s %s" % (__outfile__.name, sStdout,)
            print "vPyInit - Thread " + threading.currentThread().getName() + \
                  " number " + str(thread.get_ident())
            return True
        except Exception,e:
            print "vPyInit - Error opening %s\n%s" % (sStdout, str(e),)
            sys.exc_clear()
            return False

    elif __outfile__:
        # __outfile__.seek(0, 0)
        # __outfile__.truncate(0)
        return True
    
def ePyInit(sStdout):
    vPyInit(sStdout)
    return ""

def vPyInit(sStdout):
    bStartFile(sStdout)
    # bStartTkinter()

def vPyDeInit():
    global __root__, __outfile__
    if __outfile__:
        try:
            sys.stdout = sys.__stdout__
            sys.stderr = sys.__stderr__
            sName=__outfile__.name
            # sShowInfo('vPyDeInit', "Closing %s" % (sName,))
            __outfile__.write('INFO : vPyDeInit ' + "Closing outfile %s\n" % (sName,))
            # oLOG.shutdown()
            __outfile__.flush()
            __outfile__.close()
            __outfile__=None
        except Exception,e:
            # You probably have not stdout so no point in logging it!
            print "Error closing %s\n%s" % (__outfile__, str(e),)
            sys.exc_clear()
        
    if __root__:
        __root__.destroy()
        __root__=None

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
    assert __root__ is None
    assert __outfile__ is None

    # should check contents of test.txt
    oFd=open('test.txt', 'r')
    sContents=oFd.read()
    oFd.close()
    assert sContents.find("Level 4") > 0
    assert sContents.find("NONO") < 0
    
    if 0:
        bStartTkinter()
        assert __root__
        sShowError('Foo','Bar')

    i = iMessageBox("Hi there", "Yes No Cancel",
                    MB_YESNOCANCEL, MB_ICONINFORMATION)
    if i == IDCANCEL:
        pass
    elif i == IDYES:
        pass
    elif i == IDOK:
        pass
    # win32ui.PumpWaitingMessages()

