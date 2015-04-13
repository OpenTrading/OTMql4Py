// -*-mode: c++; fill-column: 75; tab-width: 8; coding: utf-8-dos -*-

#property copyright "Copyright 2013 OpenTrading"
#property link      "https://github.com/OpenTrading/"
#property strict

#define INDICATOR_NAME          "PyTestEA"

#include <OTMql4/OTPy27.mqh>
#include <stdlib.mqh>
//#include <OFLibLogging.mqh>

extern string sStdOutFile="_test_stdout.txt";

//extern bool bLogToFile=true;

int shift=1;
int iTicks;
string sSymbol;
int iTimeFrame;


int OnInit() {
    string sRetval, sArg;

    PyInit(sStdOutFile);

    iTimeFrame = Period();
    sSymbol = Symbol();

    sRetval=PyEvalString("sys.stdout.name");
    if (StringFind(sRetval, "<stdout>", 0) == 0) {
      Print("ERROR: NOT opened sys.stdout.name= " + sRetval);
    } else if (StringFind(sRetval, "_test_stdout.txt", 0) < 0) {
      Print("ERROR: _test_stdout.txt not in sys.stdout.name= " + sRetval);
    } else {
      Print("INFO: PyEvalString sys.stdout.name= " + sRetval);
    }

    sArg="import OTMql427";
    vPyExecuteUnicode(sArg);
    vPyExecuteUnicode("sFoobar = str(sys.last_type) + ' : ' + str(sys.last_value)");
    sRetval=PyEvalString("sFoobar");
    Print("INFO: import OTMql427 -> "+sRetval);
    vPyExecuteUnicode("sFoobar = str(dir(OTMql427))");
    sRetval=PyEvalString("sFoobar");
    Print("INFO: dir(OTMql427) -> "+sRetval);
    
    sArg="OTMql427.iMessageBox('Hi there', 'Yes No Cancel', 3, 64)";
    sRetval = PyEvalString(sArg);

    vPyExecuteUnicode("sFoobar = 'foobar'");
    sRetval=PyEvalString("sFoobar");
    if (StringFind(sRetval, "foobar", 0) == 0) {
      Print("INFO: sFoobar = " + sRetval);
    } else {
      Print("ERROR: sFoobar = " + sRetval);
    }
    /*
    sRetval=sPySafeEval("bad");
    if (sRetval != "") {
      Print("ERROR: NOT null return= " + sRetval);
    } else {
      Print("INFO: null return for bad= " + sRetval);
    }
    */
    Print("INFO: vPyExecuteUnicode bad coming up");
    vPyExecuteUnicode("bad");
    PyPrintAndClearLastError();

    vPyExecuteUnicode("sFoobar = str(sys.last_type) + ' ' + str(sys.last_value)");
    sRetval=PyEvalString("sFoobar");
    if (StringFind(sRetval, "NameError", 0) < 0) {
      Print("ERROR: vPyExecuteUnicode bad -> sys.last_type + sys.last_value= " + sRetval);
    } else {
      Print("INFO: vPyExecuteUnicode bad -> sys.last_type + sys.last_value= " + sRetval);
    }

    sRetval=PyEvalString("str(sys.last_type) + ' ' + str(sys.last_value)");
    Print("INFO: sRetval=PyEvalString - sys.last_type + ' ' + sys.last_value= " + sRetval);


    /*
    PyEvaluateSingle("sFoobar = str(sys.last_type) + ' ' + str(sys.last_value)");
    sRetval=PyEvalString("sFoobar");
    Print("INFO: PyEvaluateSingle = sys.last_type + ' ' + sys.last_value= " + sRetval);
    PyEvaluateSingle("str(sys.last_type) + ' ' + str(sys.last_value)");
    sRetval=PyEvalString("sFoobar");
    Print("INFO: PyEvaluateSingle  sys.last_type + ' ' + sys.last_value= " + sRetval);

    sRetval=PyEvalSingle("sys.stdout.name");
    if (StringFind(sRetval, "<stdout>", 0) == 0) {
    Print("ERROR: PyEvalSingle NOT opened sys.stdout.name= " + sRetval);
    } else if (StringFind(sRetval, "_python_stdout.txt", 0) < 0) {
    Print("ERROR: PyEvalSingle _python_stdout.txt not in sys.stdout.name= " + sRetval);
    } else {
    Print("INFO: PyEvalSingle sys.stdout.name= " + sRetval);
    }

    sRetval=PyEval("syntax : error");
    if (StringFind(sRetval, "ERROR:", 0) == 0) {
      Print("INFO: syntax : error detected:= " + sRetval);
    } else {
      Print("ERROR: syntax : error NOT detected:= " + sRetval);
      return(-1);
    }

    sRetval=PyEval("runtimeerror");
    if (StringFind(sRetval, "ERROR:", 0) == 0) {
      Print("INFO: runtimeerror detected:= " + sRetval);
    } else {
      Print("ERROR: runtimeerror NOT detected:= " + sRetval);
    return(-1);
    }
    */
    Print( INDICATOR_NAME + " initialized");

    return(0);
}

void OnDeinit(const int iReason) {
    //? if (iReason == INIT_FAILED) { return ; }
    vManageLowerStatus("");
    PyDeInit();
    Print( INDICATOR_NAME + " de-initialized");
}

void OnTick() {
    static datetime tNextbartime=0;

    bool bNewBar=false;
    double fEpsilon=0.0001;
    string sMsg="";

    //---- last counted bar will be recounted
    datetime tTime=iTime(sSymbol, iTimeFrame, 0);
    string sTime = TimeToStr(tTime, TIME_DATE|TIME_MINUTES) + " ";

    if (tTime != tNextbartime)
    {
      shift += 1; // = Bars - 100
      tNextbartime=tTime;
      bNewBar=true;
    } else {
      bNewBar=false;
      iTicks+=1;
    }

    if (bNewBar)
    {
      sMsg=sTime + "new bar " + shift;
      iTicks=0;
    } else {
      sMsg=sTime + "iTicks " + iTicks;
    }
    vManageLowerStatus(sMsg);
    // vPyExecuteUnicode("print '" + sMsg + "'");

}


void vManageLowerStatus(string addstatus) {
    ObjectDelete("Lower_Status");
    if (addstatus!="") {
      ObjectCreate("Lower_Status", OBJ_LABEL, 0, 0, 0);// Creating obj.
      ObjectSet("Lower_Status", OBJPROP_CORNER,3);    // Reference corner
      ObjectSet("Lower_Status", OBJPROP_XDISTANCE, 2);// X coordinate
      ObjectSet("Lower_Status", OBJPROP_YDISTANCE, 1);// Y coordinate
      ObjectSetText("Lower_Status", addstatus, 8, "Verdana", Yellow);
      }
    }

