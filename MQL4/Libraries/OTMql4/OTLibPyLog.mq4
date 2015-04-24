// -*-mode: c; c-style: stroustrup; c-basic-offset: 4; coding: utf-8-dos -*-

/*
This will provide our logging functions that work with Python.
See OTLibLog for just a skeleton logging.

We introduce a global variable fDebugLevel which ranges from 0 to 5:
"PANIC", "ERROR", "WARNING", "INFO", "DEBUG", "TRACE"

If you set the variable to 1, you will only see errors; if you set
it to 2 you will see warnings and errors...

The Mt4 code can use vLog(iLevel, uMsg) to log accordingly.
The Python code can use vLog(iLevel, sMsg) to log accordingly.

*/

#property copyright "Copyright 2014 Open Trading"
#property link      "https://github.com/OpenTrading/"
#property library

#include <OTMql4/OTPy27.mqh>

/* we override vLog from OTLibLog */
#include <OTMql4/OTLibLog.mqh>

/* 
 We introduce 6 levels of logging: 0 - 5
*/
string dLogArray[] = {"PANIC", "ERROR", "WARNING", "INFO", "DEBUG", "TRACE"};


// floating point rounding error
double fEPSILON=0.01;

void vSetLogLevel(int i) {

  GlobalVariableSet("fDebugLevel", i);
  double fPythonUsers;
  fPythonUsers=GlobalVariableGet("fPythonUsers");
  if (fPythonUsers > 0.0) {
    // leave Python at max logging for now
    // vPyExecuteUnicode("oLOG.setLevel(50 -10*"+i+")");
  }

}

int iGetLogLevel() {
  int iDebugLevel;
  double fDebugLevel;

  fDebugLevel=GlobalVariableGet("fDebugLevel");
  if (fDebugLevel < fEPSILON) {
    iDebugLevel=3;
    GlobalVariableSet("fDebugLevel", 3.0);
  } else {
    iDebugLevel=MathRound(fDebugLevel);
  }
  return(iDebugLevel);
}

void vLog (int iLevel, string uMsg) {

  uMsg=Symbol()+Period()+" "+uMsg;

  if (iLevel <= iGetLogLevel()) {
      Print(dLogArray[iLevel]+": "+uMsg);
  }

  double fPythonUsers;
  fPythonUsers=GlobalVariableGet("fPythonUsers");
  if (fPythonUsers > 0.0) {
    vPyExecuteUnicode("OTMql427.vLog(" + iLevel + ", '''" + uMsg + "''')");
    // a level of 0 is usually a panic and raises a messagebox
    if (iLevel <= 1 && !IsOptimization() && !IsTesting() ) {
      vPyExecuteUnicode("OTMql427.iMessageBox('''" + uMsg + "''', '"+Symbol()+Period()+
		"', OTMql427.MB_OK, OTMql427.MB_ICONERROR)");
    }
  }
}
