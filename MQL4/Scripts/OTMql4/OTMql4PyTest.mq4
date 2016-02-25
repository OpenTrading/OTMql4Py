// -*-mode: c; c-style: stroustrup; c-basic-offset: 4; coding: utf-8-dos -*-

#property copyright "Copyright 2014 Open Trading"
#property link      "https://github.com/OpenTrading/"

//  A simple test Script that doesn't do much, but it's a start.
//  Attach it to a chart, select the tests you want to run,
//  and a MessageBox will pop up to tell you if it passed or failed.

#property show_inputs

#include <OTMql4/OTLibLog.mqh>
#include <OTMql4/OTLibPy27.mqh>

#include <WinUser32.mqh>

extern string sStdOutFile="_test_OTMql4PyTest.txt";

//  We will put each test as a boolean external input so the user
//  can select which tests to run.

extern bool bTestStdout=true;
extern bool bTestDatatypes=true;
extern bool bTestImport=true;
extern bool bTestMessageBox=true;
extern bool bTestSyntaxError=true;
extern bool bTestRuntimeError=true;

double fEps=0.000001;

void vAlert(string uText) {
    MessageBox(uText, "OTMql4PyTest.mq4", MB_OK|MB_ICONEXCLAMATION);
}

string eTestStdout(string uFile) {
    int iErr = 0;
    string uRetval = "";

    uRetval = uPyEvalUnicode("sys.stdout.name");
    if (StringFind(uRetval, "<stdout>", 0) == 0) {
      uRetval = "ERROR: NOT opened sys.stdout.name= " + uRetval;
      Print(uRetval);
    } else if (StringFind(uRetval, uFile, 0) < 0) {
      uRetval = "ERROR: " + uFile +" not in sys.stdout.name= " + uRetval;
    } else {
      Print("INFO: uPyEvalUnicode sys.stdout.name= " + uRetval);
      uRetval = "";
    }
    return(uRetval);
}

string eTestDatatypes() {
    int iErr = 0;
    string uRetval = "";
    double fRetval;
    int iRetval;
    string uArg;

    vPyExecuteUnicode("sFoobar = 'foobar'");
    uRetval = uPyEvalUnicode("sFoobar");
    if (StringFind(uRetval, "foobar", 0) != 0) {
      uRetval = "ERROR: sFoobar = " + uRetval;
      Print(uRetval);
      return(uRetval);
    }

    uArg = "2.0 + 2.0";
    fRetval = fPyEvalDouble(uArg);
    if (MathAbs(fRetval - 4.0) > fEps) {
      uRetval = "ERROR: 4.0 NOT detected:= " + fRetval;
      Print(uRetval);
      return(uRetval);
    }

    uArg = "2 + 2";
    iRetval = iPyEvalInt(uArg);
    if (iRetval - 4 != 0) {
      uRetval = "ERROR: 4 NOT detected:= " + iRetval;
      Print(uRetval);
      return(uRetval);
    }

    /* FixMe: test lists */

    return("");
}

string eTestImport() {
    int iErr=0;
    string uRetval="";
    string uArg;

    uArg = "import OTMql427";
    uRetval = ePySafeExec(uArg);
    if (StringCompare(uRetval, "") != 0) {
	vAlert("Error in Python execing: " + uArg + " -> " + uRetval);
	return(uRetval);
    }

    uArg = "str(dir(OTMql427))";
    uRetval = uPySafeEval(uArg);
    if (StringFind(uRetval, "ERROR:", 0) == 0) {
	vAlert("Error in Python execing: " + uArg + " -> " + uRetval);
	return(uRetval);
    }
    
    Print("INFO: " +uArg +" -> " +uRetval);
    return("");
}

string eTestMessageBox() {
    int iErr = 0;
    string uRetval = "";
    string uArg;

    uArg = "OTMql427.iMessageBox('Test of OTMql427.iMessageBox', 'Yes No Cancel', 3, 64)";
    uRetval = uPyEvalUnicode(uArg);

    return("");
}

string eTestSyntaxError() {
    int iErr = 0;
    string uRetval = "";

    uRetval = uPySafeEval("screw up on purpose");
    if (StringFind(uRetval, "ERROR:", 0) == 0) {
        Print("INFO: syntax error on purpose detected -> " + uRetval);
        return("");
    } else {
        uRetval = "ERROR: syntax error NOT detected -> " + uRetval;
        Print(uRetval);
        return(uRetval);
    }
}

string eTestRuntimeError() {
    int iErr = 0;
    string uRetval = "";

    uRetval = uPySafeEval("provokeanerror");
    if (StringFind(uRetval, "ERROR:", 0) == 0) {
        Print("INFO: eTestRuntimeError detected -> " + uRetval);
        return("");
    } else {
        uRetval ="ERROR: eTestRuntimeError NOT detected -> " + uRetval;
        Print(uRetval);
        return(uRetval);
    }
}

void OnStart() {
    string uRetval = "";

    if (iPyInit(sStdOutFile) != 0) {
        return;
    }
    // groan - need an Mt4 eval!
    if ( bTestStdout == true ) {
        uRetval = eTestStdout(sStdOutFile);
        if (uRetval != "") { vAlert(uRetval); }
    }
    if ( bTestDatatypes == true ) {
        uRetval = eTestDatatypes();
        if (uRetval != "") { vAlert(uRetval); }
    }
    if ( bTestImport == true ) {
        uRetval = eTestImport();
        if (uRetval != "") { vAlert(uRetval); }
    }
    if ( bTestMessageBox == true ) {
        uRetval = eTestMessageBox();
        if (uRetval != "") { vAlert(uRetval); }
    }
    if ( bTestSyntaxError == true ) {
        uRetval = eTestSyntaxError();
        if (uRetval != "") { vAlert(uRetval); }
    }
    if ( bTestRuntimeError == true ) {
        uRetval = eTestRuntimeError();
        if (uRetval != "") { vAlert(uRetval); }
    }
}

void OnDeinit(const int iReason) {
    //  FixMe: we dont really want to deinit for all reasons;
    //  It is untested as to whether this will cause access violations.

    /*
      See http://docs.mql4.com/check/UninitializeReason
      0 Script finished its execution independently.
      REASON_REMOVE     1       Expert removed from chart.
      REASON_RECOMPILE  2       Expert recompiled.
      REASON_CHARTCHANGE        3       symbol or timeframe changed on the chart.
      REASON_CHARTCLOSE 4       Chart closed.
      REASON_PARAMETERS 5       Inputs parameters was changed by user.
      REASON_ACCOUNT    6       Other account activated.
    */

    //  recompiling and reloading should not require reinitializing.
    //  if (iReason == 2) {return;}
    //  BUT we have no way of telling if the OnStart is called from a recompile.

    //  We are also seeing iReason == 0 when Mt4 sees a script has been recompiled.

    vPyDeInit();
}
