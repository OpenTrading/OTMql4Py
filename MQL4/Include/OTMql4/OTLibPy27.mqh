// -*-mode: c; c-style: stroustrup; c-basic-offset: 4; coding: utf-8-dos -*-

#property copyright "Copyright 2015 OpenTrading"
#property link      "https://github.com/OpenTrading/"

#import "OTMql4/OTLibPy27.ex4"

void vPyExecuteUnicode (string uSource);
int iPyEvaluateUnicode (string uSource);
int iPyNewStringUnicode(string &uSource);
int iPyLookupDictUnicode(int p_dict, string uName);
int iPyInit(string sStdOut);
void vPyOutEmpty();
void vPyPrintAndClearLastError();
string ePySafeExec(string uSource);
string uPySafeEval(string uSource);
void vPanic(string uReason);
int iPySafeExec(string uArg);
int iPyEvalInt(string uSource);
double fPyEvalDouble(string uSource);
string uPyEvalUnicode(string uSource);
int iPyListAppendInt(string list_name, int &array[]);
int iPyListAppendDouble(string list_name, double &array[]);
int iPyListAppendString(string list_name, string &array[]);
int OnDeinit();
void vPyDeInit();

string uChartName(string uSymbol, int iPeriod, long iWindowId, int iExtra);
