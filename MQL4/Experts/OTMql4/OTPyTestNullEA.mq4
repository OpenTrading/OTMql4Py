// -*-mode: c; c-style: stroustrup; c-basic-offset: 4; coding: utf-8-dos -*-

#property copyright "Copyright 2013 OpenTrading"
#property link      "https://github.com/OpenTrading/"
#property strict

#define INDICATOR_NAME          "PyTestNullEA"

#include <OTMql4/OTPy27.mqh>

extern string sStdOutFile="_test_null_stdout.txt";

int OnInit() {
    string uArg, uRetval;

    if (iPyInit(sStdOutFile) != 0) {
	return(-1);
    }

    Print("Called iPyInit");
    /* too long to fit a log line */
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
