// -*-mode: c; c-style: stroustrup; c-basic-offset: 4; coding: utf-8; encoding: utf-8-dos -*-

#property copyright "Copyright 2014 Open Trading"
#property link      "https://github.com/OpenTrading/"

#property show_inputs

#include <OTMql4/OTPy27.mqh>

#include <WinUser32.mqh>

extern string sStdOutFile="_test_OTMql4PyZmqPub.txt";

/*
We will put each test as a boolean external input so the user
can select which tests to run.
*/
extern bool bTestImportZmq=true;

double fEps=0.000001;

void vAlert(string uText) {
  MessageBox(uText, "OTMql4PyTest.mq4", MB_OK|MB_ICONEXCLAMATION);
}

string eTestImportZmq() {
    int iErr = 0;
    string uRetval = "";
    string uArg;

    uArg="import zmq";
    vPyExecuteUnicode(uArg);
    vPyExecuteUnicode("sFoobar = str(dir(zmq))");
    uRetval=uPyEvalUnicode("sFoobar");
    if (StringFind(uRetval, "exceptions.SystemError", 0) >= 0) {
      // We are seeing this during testing under adverse conditions
      uRetval = "PANIC: import zmq failed - we MUST restart Mt4"  + uRetval;
      vAlert(uRetval);
      return(uRetval);
    }
    Print("INFO: dir(zmq) -> "+uRetval);
    vPyExecuteUnicode("sFoobar = zmq.zmq_version()");
    Print("INFO: zmq.zmq_version() -> "+uRetval);

    return("");
}

void OnStart() {
    string uRetval = "";

    if (iPyInit(sStdOutFile) != 0) {
      return;
    }
    if ( bTestImportZmq == true ) {
        uRetval = eTestImportZmq();
        if (uRetval != "") { vAlert(uRetval); }
    }
}

void OnDeinit(const int iReason) {
    // FixMe: we dont really want to deinit for all reasons;
    // It is untested as to whether this will cause access violations.

    /*
    See http://docs.mql4.com/check/UninitializeReason
    0	Script finished its execution independently.
    REASON_REMOVE	1	Expert removed from chart.
    REASON_RECOMPILE	2	Expert recompiled.
    REASON_CHARTCHANGE	3	symbol or timeframe changed on the chart.
    REASON_CHARTCLOSE	4	Chart closed.
    REASON_PARAMETERS	5	Inputs parameters was changed by user.
    REASON_ACCOUNT	6	Other account activated.
    */

    // recompiling and reloading should not require reinitializing.
    // if (iReason == 2) {return;}
    // BUT we have no way of telling if the OnStart is called from a recompile.

    // We are also seeing iReason == 0 when Mt4 sees a script has been recompiled.

    vPyDeInit();
}
