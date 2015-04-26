// -*-mode: c; c-style: stroustrup; c-basic-offset: 4; coding: utf-8; encoding: utf-8-dos -*-

#property copyright "Copyright 2013 OpenTrading"
#property link      "https://github.com/OpenTrading/"
#property strict

#define INDICATOR_NAME          "PyTestNullEA"

#include <OTMql4/OTPy27.mqh>

extern string sStdOutFile="../../logs/_test_PyTestNullEA.txt";

int OnInit() {
    int iRetval;
    string uArg, uRetval;

    iRetval = iPyInit(sStdOutFile);
    if (iRetval != 0) {
	return(iRetval);
    }

    Print("Called iPyInit");
    /* sys.path is too long to fit a log line */
    uArg="str(sys.path[0])";
    uRetval = uPyEvalUnicode(uArg);
    Print("sys.path = "+uRetval);
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
