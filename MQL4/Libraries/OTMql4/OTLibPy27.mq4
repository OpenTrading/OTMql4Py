// -*-mode: c; c-style: stroustrup; c-basic-offset: 4; coding: utf-8-dos -*-

#property copyright "Copyright 2014 Open Trading"
#property link      "https://github.com/OpenTrading/"
#property library

//  This will provide our logging functions that work with Python.
//  See OTLibLog for just a skeleton logging.
//
//  We introduce a global variable fDebugLevel which ranges from 0 to 5:
//  "PANIC", "ERROR", "WARNING", "INFO", "DEBUG", "TRACE"
//
//  If you set the variable to 1, you will only see errors; if you set
//  it to 2 you will see warnings and errors...
//
//  The Mt4 code can use vLog(iLevel, uMsg) to log accordingly.
//  The Python code can use vLog(iLevel, sMsg) to log accordingly.
//

#include <WinUser32.mqh>
#include <OTMql4/OTLibLog.mqh>
#include <OTMql4/OTPy27.mqh>


//  Wrappers around the imported funtions for strings:
//  they expect uchar[] arrays, not unicode strings.
void vPyExecuteUnicode (string uSource) {
    uchar sCharData[];
    StringToCharArray(uSource, sCharData);
    PyExecute(sCharData);
}

int iPyEvaluateUnicode (string uSource) {
    int iRetval;
    uchar sCharData[];
    StringToCharArray(uSource, sCharData);
    iRetval = PyEvaluate(sCharData);
    return(iRetval);
}

/* FixMe: this is a pointer to a string:
   how do we do a pointer to a uchar[] pointer?
*/
int iPyNewStringUnicode(string &uSource) {
    int iRetval;
    uchar sCharData[];
    StringToCharArray(uSource, sCharData);
    iRetval = PyNewString(sCharData);
    return(iRetval);
}

int iPyLookupDictUnicode(int p_dict, string uName) {
    int iRetval;
    uchar sCharData[];
    StringToCharArray(uName, sCharData);
    iRetval = PyLookupDict(p_dict, sCharData);
    return(iRetval);
}


//  Below are some higher level abstractions, here you dont have to
//  care about reference counting when using the functions, you will
//  not be exposed to handles of python objects.


int iPyInit(string sStdOut) {
    //  Initializes the Python environment. This should be called
    //  from your OnInit() function. It is safe to call it a second time;
    //  subsequent calls will just be ignored.
    //
    //  It should return 0.
    //
    //  A return value of -1 is a panic: remove the expert if it requires Python.
    string uRetval, uArg;
    double fPythonUsers;
    double fDebugLevel;
    string uTerminalPath;

    if (!PyIsInitialized()) {
        vLogInit();
        // Old Mt4 layout:
        // uTerminalPath = TerminalPath();
        uTerminalPath = TerminalInfoString(TERMINAL_DATA_PATH);
        //  See the explanation and notes in
        //  https://github.com/OpenTrading/OTMql4Lib/wiki/Installation
        Print("iPyInit: Starting OTPy27.mqh in " +  uTerminalPath);
        // Thread specific??
        if (GlobalVariableCheck("fPythonUsers") == true) {
            GlobalVariableDel("fPythonUsers");
        }
        PyInitialize();
        Print("iPyInit: called PyInitialize ");
        // import the system modules that we will need
        uArg = "import os, sys, logging, traceback";
        vPyExecuteUnicode(uArg);

        // later we will use these to clear execution errors
        // but they are undefined in Python until the first error
        uArg = "sys.last_type=''";
        vPyExecuteUnicode(uArg);
        uArg = "sys.last_value=''";
        vPyExecuteUnicode(uArg);

        // we change to the metatrader directory to know where we are
        vPyExecuteUnicode("os.chdir(os.path.join(r'" + uTerminalPath + "'))");
        // NOT uArg = "sys.path.insert(0, os.getcwd())";
        // we insert the MQL4\Python directory on the sys.path
        uArg = "sys.path.insert(0, os.path.join(r'" + uTerminalPath + "', 'MQL4', 'Python'))";
        vPyExecuteUnicode(uArg);
        // this path should have been created on the install
        // and should have a file __init__.py in it
        /* ToDo: touch __init__.py */

        /* make sure OTMql427.py is there */
        uArg = "import OTMql427";
        vPyExecuteUnicode(uArg);
        // VERY IMPORTANT: if the import failed we MUST PANIC
        vPyExecuteUnicode("sFoobar = '%s : %s' % (sys.last_type, sys.last_value,)");
        uRetval = uPyEvalUnicode("sFoobar");
        if (StringFind(uRetval, "exceptions.SystemError", 0) >= 0) {
            uRetval = "PANIC: import OTMql427 failed - we MUST restart Mt4"  + uRetval;
            Alert(uRetval);
            return(-1);
        }
        // we will keep track of the number of charts using Python
        // so that we can call OnDeinit if the number drops to 0
        // We want it to be temporary, not saved across restarts
        GlobalVariableTemp("fPythonUsers");
        fPythonUsers = 0.0;
    } else {
        fPythonUsers = GlobalVariableGet("fPythonUsers");
        Print("PyInit: Incrementing fPythonUsers from: " + fPythonUsers);
        fDebugLevel = iGetLogLevel();
    }

    if (fPythonUsers < 0.1) {
        // OTMql427.ePyInit is idempotent
        uRetval = uPyEvalUnicode("OTMql427.ePyInit('" + sStdOut + "')");
        if (uRetval != "") {
            uArg = "ERROR: failed OTMql427.ePyInit - " + uRetval + "";
            vPyExecuteUnicode("sFoobar = '%s : %s' % (sys.last_type, sys.last_value,)");
            uRetval = uPyEvalUnicode("sFoobar");
            Alert(uArg +" " +uRetval);
            return(-2);
        }
        Print("INFO: Python stdout to file: " + sStdOut);
        uArg = "sys.stdout.flush()";
        vPyExecuteUnicode(uArg);

        fPythonUsers = 1.0;
    } else {
        fPythonUsers += 1.0;
    }

    GlobalVariableSet("fPythonUsers", fPythonUsers);

    /* not Tmp */
    if (GlobalVariableCheck("fDebugLevel") == false) {
        /* 1= Error, 2 = Warn, 3 = Info, 4 = Debug, 5 = Trace */
        fDebugLevel = 2.0;
        GlobalVariableSet("fDebugLevel", fDebugLevel);
    }
    return(0);
}

void vPyOutEmpty() {
    //  empty the stdout file (where the redirected print output and errors go)
    string uArg;
    uArg = "__outfile__.seek(0, os.SEEK_SET)";
    vPyExecuteUnicode(uArg);
    uArg = "__outfile__.truncate(0)";
    vPyExecuteUnicode(uArg);
}

void vPyPrintAndClearLastError() {
    //  You MUST do something to clear any error condition
    //  or the system will crash, as documented in the Python manual.
    // PyErrPrint();
    vPyExecuteUnicode("sys.exc_clear()");

    string uSource = "hasattr(sys, 'last_type') and str(sys.last_value) or ''";
    int p_res = iPyEvaluateUnicode(uSource);
    if (p_res <= 0) {
        Print("ERROR: vPyPrintAndClearLastError - failed evaluating: " + uSource);
        vPyExecuteUnicode("sys.exc_clear()");
        return;
    }
    string res = uPyGetUnicodeFromPointer(p_res);
    PyDecRef(p_res);

    Print("ERROR: " + res);
}

string uPySafeEval(string uSource) {
    //  Evaluate a python expression that will evaluate to a string
    //  and return its value
    //
    //  In the caller you should have something like:
    //  {{{
    //  if (StringFind(uRetval, "ERROR:", 0) == 0) {
    //  Print("Error in Python evaluating: " + uSource + "\n" + res);
    //  <do something as a result of the failure>
    //  }
    //  }}}

    string uRetval="";
    string sSrc;
    sSrc = "OTMql427.sPySafeEval('''"+uSource+"''')";

    int p_res = iPyEvaluateUnicode(sSrc);
    if (p_res <= 0) {
        Print("ERROR: PySafeEval - failed evaluating: " + uSource);
        vPyPrintAndClearLastError();
        return ("");
    }
    uRetval = uPyGetUnicodeFromPointer(p_res);
    PyDecRef(p_res);

    return(uRetval);
}

void vPanic(string uReason) {
    //  A panic prints an error message and then aborts
    Print("PANIC: " + uReason);
    MessageBox(uReason, "PANIC!", MB_OK|MB_ICONEXCLAMATION);
}

int iPySafeExec(string uArg) {
    string uRetval;

    vPyExecuteUnicode(uArg);
    vPyExecuteUnicode("sFoobar = '%s : %s' % (sys.last_type, sys.last_value,)");
    uRetval = uPyEvalUnicode("sFoobar");
    if (StringFind(uRetval, "exceptions.SystemError", 0) >= 0) {
        // VERY IMPORTANT: if the ANYTHING fails with SystemError we MUST PANIC
        // Were seeing this during testing after an uninit 2 reload
        uRetval = "PANIC: " +uArg +" failed - we MUST restart Mt4:"  + uRetval;
        vPanic(uRetval);
        return(-2);
    }
    if (StringFind(uRetval, "Error", 0) >= 0) {
        uRetval = "PANIC: " +uArg +" failed:"  + uRetval;
        vPanic(uRetval);
        return(-1);
    }
    return(0);
}


int iPyEvalInt(string uSource) {
    //  Evaluate a python expression that will evaluate to an integer
    //  and return its value
    int p_res = iPyEvaluateUnicode(uSource);
    if (p_res <= 0) {
        Print("ERROR: PyEvalInt - failed evaluating: " + uSource);
        vPyExecuteUnicode("sys.exc_clear()");
        return (0);
    }
    int res = PyGetInt(p_res);
    PyDecRef(p_res);
    return(res);
}

double fPyEvalDouble(string uSource) {
    //  Evaluate a python expression that will evaluate to a double
    //  and return its value
    //
    int p_res = iPyEvaluateUnicode(uSource);
    if (p_res <= 0) {
        Print("ERROR: PyEvalDouble - failed evaluating: " + uSource);
        vPyExecuteUnicode("sys.exc_clear()");
        // FixMe: need NaN
        return (0.0);
    }
    double res = PyGetDouble(p_res);
    PyDecRef(p_res);
    return(res);
}

/**
* Evaluate a python expression that will evaluate to a string
* and return its value. Better to use uPySafeEval where possible.
*/
string uPyEvalUnicode(string uSource) {
    int p_res = iPyEvaluateUnicode(uSource);
    if (p_res <= 0) {
        Print("ERROR: uPyEvalUnicode - failed evaluating: " + uSource);
        vPyExecuteUnicode("sys.exc_clear()");
        //vPyPrintAndClearLastError();
        return ("");
    }
    string uRetval = uPyGetUnicodeFromPointer(p_res);
    PyDecRef(p_res);
    /* We are not sure what this is: perhaps when an unhandled exception
       occurs in Python, it kills the thread that Mt4 is talking to?
       It's serious error, and we should look to see where select
       enters into the communications process.
       Take the precaution of calling sys.exc_clear or
       FixMe: call sys.exc_clear on any error?

       Maybe provoked by and error in vPikaCallbackOnListener
       which I assume is in the main thread?
    */
    if (StringFind(uRetval, "select.error", 0) >= 0) {
        //? Panic (10038, "Windows Error 0x2736")
        Print("ERROR: uPyEvalUnicode - select.error evaluating: " + uSource);
        vPyExecuteUnicode("sys.exc_clear()");
        return(uRetval);
    }
    return(uRetval);
}

int iPyListAppendInt(string list_name, int &array[]) {
    //  append the array of int to the python list given by its name.
    //  the list must already exist. The same could be achieved
    //  by putting vPyExecuteUnicode() calls with generated python code
    //  into a loop but this would invoke parser and compiler for
    //  every new list item, directly accessing the python objects
    //  like it is done here is far more effective.

    int list,item,len,i;
    list = iPyEvaluateUnicode(list_name);
    len = ArraySize(array);
    for (i=0; i<len; i++) {
        item = PyNewInt(array[i]);
        PyListAppend(list, item);
        PyDecRef(item);
    }
    len = PyListSize(list);
    PyDecRef(list);
    return(len);
}

int iPyListAppendDouble(string list_name, double &array[]) {
    //  append the array of double to the python list given by its name.
    //  the list must already exist.
    //

    int list,item,len,i;
    list = iPyEvaluateUnicode(list_name);
    len = ArraySize(array);
    for (i=0; i<len; i++) {
        item = PyNewDouble(array[i]);
        PyListAppend(list, item);
        PyDecRef(item);
    }
    len = PyListSize(list);
    PyDecRef(list);
    return(len);
}

int iPyListAppendString(string list_name, string &array[]) {
    //  Append the array of string to the python list given by its name.
    //  the list must already exist.
    //
    int list,item,len,i;
    list = iPyEvaluateUnicode(list_name);
    len = ArraySize(array);
    for (i=0; i<len; i++){
        item = iPyNewStringUnicode(array[i]);
        PyListAppend(list, item);
        PyDecRef(item);
    }
    len = PyListSize(list);
    PyDecRef(list);
    return(len);
}


void vPyDeInit() {
    double fPythonUsers;

    fPythonUsers = GlobalVariableGet("fPythonUsers");
    // FixMe: this is not showing up in the log
    Print("INFO vPyDeInit: Decrementing fPythonUsers from: " + fPythonUsers);
    fPythonUsers -= 1.0;

    if (PyIsInitialized() && fPythonUsers < 0.1) {
        vPyExecuteUnicode("OTMql427.vPyDeInit()");
        fPythonUsers = 0.0;
    }

    if (fPythonUsers < 0.1) {
        bool bRetval=GlobalVariableDel("fPythonUsers");
        int iError=GetLastError();
        if (!bRetval) {
            Print("ERROR vPyDeInit: deleting global variable fPythonUsers" +  iError);
        }
        // leave this so that it's saved for the next run
        // bRetval = GlobalVariableDel("fDebugLevel");
    } else {
        GlobalVariableSet("fPythonUsers", fPythonUsers);
    }
}

string uChartName(string uSymbol, int iPeriod, long iWindowId, int iExtra=0) {
    //  We will need a unique identifier for each chart
    string uRetval="";

    uRetval = StringFormat("oChart_%s_%i_%X_%i", uSymbol, iPeriod, iWindowId, iExtra);
    return(uRetval);
}
