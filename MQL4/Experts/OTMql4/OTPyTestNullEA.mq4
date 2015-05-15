// -*-mode: c; c-style: stroustrup; c-basic-offset: 4; coding: utf-8-dos -*-

#property copyright "Copyright 2013 OpenTrading"
#property link      "https://github.com/OpenTrading/"
#property strict

#define INDICATOR_NAME          "PyTestNullEA"

#include <OTMql4/OTLibLog.mqh>
#include <OTMql4/OTLibPy27.mqh>

extern string sStdOutFile="../../Logs/_test_PyTestNullEA.txt";

#include <WinUser32.mqh>
void vPanic(string uReason) {
    "A panic prints an error message and then aborts";
    vError("PANIC: " + uReason);
    MessageBox(uReason, "PANIC!", MB_OK|MB_ICONEXCLAMATION);
    ExpertRemove();
}

int OnInit() {
    int iRetval;
    string uArg, uRetval;

    iRetval = iPyInit(sStdOutFile);
    if (iRetval != 0) {
	return(iRetval);
    }
    Print("Called iPyInit");
    
    uArg="import os";
    iRetval = iPySafeExec(uArg);
    if (iRetval <= -2) {
	// VERY IMPORTANT: if the ANYTHING fails with SystemError we MUST PANIC
	ExpertRemove();
	return(-2);
    } else if (iRetval <= -1) {
	return(-2);
    }
	
	
    /* sys.path is too long to fit a log line */
    uArg="str(sys.path[0])";
    uRetval = uPyEvalUnicode(uArg);
    Print("sys.path = "+uRetval);

    iRetval = iPyEvalInt("os.getpid()");
    Print("os.getpid() = " + iRetval);

    return (0);
}
int iTick=0;

void OnTick () {
    iTick+=1;
    Print("iTick="+iTick);
}

void OnDeinit(const int iReason) {
    //? if (iReason == INIT_FAILED) { return ; }
    vPyDeInit();
}
