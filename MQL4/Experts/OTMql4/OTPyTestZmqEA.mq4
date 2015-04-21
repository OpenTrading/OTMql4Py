// -*-mode: c; c-style: stroustrup; c-basic-offset: 4; coding: utf-8-dos -*-

#property copyright "Copyright 2015 OpenTrading"
#property link      "https://github.com/OpenTrading/"
#property strict

#define INDICATOR_NAME          "PyTestZmqEA"

extern int iSEND_PORT=2027;
extern int iRECV_PORT=2028;
// can replace this with the IP address of an interface - not lo
extern string uBIND_ADDRESS="127.0.0.1";
extern string uStdOutFile="_test_PyTestZmqEA.txt";

#include <OTMql4/OTZmqBarInfo.mqh>

#include <OTMql4/OTLibLog.mqh>
//#include <OTMql4/OTZmqProcessCmd.mqh>
#include <OTMql4/OTPy27.mqh>
#include <OTMql4/OTPyZmq.mqh>

#include <WinUser32.mqh>

int iTIMER_INTERVAL_SEC = 10;
int iCONTEXT = -1;
double fPY_ZMQ_CONTEXT_USERS = 0.0;

string uSYMBOL;
int iTIMEFRAME;
int iACCNUM;

int iTick=0;
int iBar=1;

void vPanic(string uReason) {
    "A panic prints an error message and then aborts";
    vError("PANIC: " + uReason);
    MessageBox(uReason, "PANIC!", MB_OK|MB_ICONEXCLAMATION);
    ExpertRemove();
}

int iIsEA=1;
string uCHART_NAME="";
double fDebugLevel=0;

string sStringReplace(string uHaystack, string uNeedle, string replace="") {
    string left, right;
    int start=0;
    int rlen = StringLen(replace);
    int nlen = StringLen(uNeedle);
    
    while (start > -1) {
	start = StringFind(uHaystack, uNeedle, start);
	if (start > -1) {	
	    if(start > 0) {
		left = StringSubstr(uHaystack, 0, start);
	    } else {
		left="";
	    }
	    right = StringSubstr(uHaystack, start + nlen);
	    uHaystack = left + replace + right;
	    start = start + rlen;
	}	
    }
    return (uHaystack);
}

string uSafeString(string uSymbol) {
    uSymbol = sStringReplace(uSymbol, "!", "");
    uSymbol = sStringReplace(uSymbol, "#", "");
    uSymbol = sStringReplace(uSymbol, "-", "");
    uSymbol = sStringReplace(uSymbol, ".", "");
    return(uSymbol);
}


int OnInit() {
    int iRetval;
    string uArg, uRetval;

    if (GlobalVariableCheck("fPyZmqContextUsers") == true) {
        fPY_ZMQ_CONTEXT_USERS=GlobalVariableGet("fPyZmqContextUsers");
    } else {
        fPY_ZMQ_CONTEXT_USERS = 0.0;
    }
    if (fPY_ZMQ_CONTEXT_USERS > 0.1) {
	iCONTEXT = MathRound(GlobalVariableGet("fPyZmqContext"));
	if (iCONTEXT < 1) {
	    vError("OnInit: unallocated context");
	    return(-1);
	}
        fPY_ZMQ_CONTEXT_USERS += 1.0;
    } else {
	iRetval = iPyInit(uStdOutFile);
	if (iRetval != 0) {
	    return(iRetval);
	}
	Print("Called iPyInit successfully");
	
	uSYMBOL=Symbol();
	iTIMEFRAME=Period();
	iACCNUM=AccountNumber();
	//? add iACCNUM +"|" ? It may change during the charts lifetime
	uCHART_NAME="oChart"+"_"+uSafeString(uSYMBOL)+"_"+Period()+"_"+iIsEA;
    
	uArg="import zmq";
	vPyExecuteUnicode(uArg);
	// VERY IMPORTANT: if the import failed we MUST PANIC
	vPyExecuteUnicode("sFoobar = '%s : %s' % (sys.last_type, sys.last_value,)");
	uRetval=uPyEvalUnicode("sFoobar");
	if (StringFind(uRetval, "exceptions.SystemError", 0) >= 0) {
	    // Were seeing this during testing after an uninit 2 reload
	    uRetval = "PANIC: import zmq failed - we MUST restart Mt4:"  + uRetval;
	    vPanic(uRetval);
	    return(-2);
	}
	vPyExecuteUnicode("from OTMql427 import ZmqChart");
	/*
	vLog(LOG_INFO, "rInstance of oZmqChart creating "+
	     uCHART_NAME +" iIsEA "+ iIsEA);
	*/
	vPyExecuteUnicode(uCHART_NAME+"=ZmqChart.ZmqChart('" +
			  Symbol() + "'," + Period() + ", " + iIsEA + ", " +
			  "iSpeakerPort=" + iSEND_PORT + ", " +
			  "iListenerPort=" + iRECV_PORT + ", " +
			  "sIpAddress='" + uBIND_ADDRESS + "', " +
			  "iDebugLevel=" + MathRound(fDebugLevel) + ", " +
			  ")");
	vPyExecuteUnicode("sFoobar = '%s : %s' % (sys.last_type, sys.last_value,)");
	uRetval = uPySafeEval("sFoobar");
	if (StringFind(uRetval, "ERROR:", 0) >= 0) {
	    uRetval = "ERROR: ZmqChart.ZmqChart failed: "  + uRetval;
	    vPanic(uRetval);
	    return(-3);
	}
			  
	iCONTEXT = iPyEvalInt("id(ZmqChart.oCONTEXT)");
	GlobalVariableTemp("fPyZmqContext");
	GlobalVariableSet("fPyZmqContext", iCONTEXT);
	
        fPY_ZMQ_CONTEXT_USERS = 1.0;
	
    }
    GlobalVariableSet("fPyZmqContextUsers", fPY_ZMQ_CONTEXT_USERS);
    vDebug("OnInit: fPyZmqContextUsers=" + fPY_ZMQ_CONTEXT_USERS);

    EventSetTimer(iTIMER_INTERVAL_SEC);
    return (0);
}

/*
OnTimer is called every iTIMER_INTERVAL_SEC (10 sec.)
which allows us to use Python to look for Zmq inbound messages,
or execute a stack of calls from Python to us in Metatrader.
*/
void OnTimer() {
    string uRetval="";
    string uMessage;
    string uMess;
    bool bRetval;

    /* timer events can be called before we are ready */
    if (GlobalVariableCheck("fPyZmqContextUsers") == false) {
      return;
    }
    iCONTEXT = MathRound(GlobalVariableGet("fPyZmqContext"));
    if (iCONTEXT < 1) {
	vWarn("OnTick: unallocated context");
        return;
    }

    // same as Time[0] - the bar time not the real time
    datetime tTime=iTime(uSYMBOL, iTIMEFRAME, 0);
    string sTime = TimeToStr(tTime, TIME_DATE|TIME_MINUTES) + " ";
    string uType = "timer";
	
    uMess = iACCNUM +"|" +uSYMBOL +"|" +iTIMEFRAME +"|" + sTime;

    uRetval = uPySafeEval(uCHART_NAME+".eSendOnSpeaker('" +uType +"', '" +uMess +"')");
    if (StringFind(uRetval, "ERROR:", 0) >= 0) {
	uRetval = "ERROR: eSendOnSpeaker " +uType +" failed: "  + uRetval;
	vWarn("OnTimer: " +uRetval);
	return;
    }
    // the uRetval should be empty - otherwise its an error
    if (uRetval == "") {
	vDebug("OnTimer: " +uRetval);
    } else {
	vWarn("OnTimer: " +uRetval);
    }
}

void OnTick() {
    static datetime tNextbartime;

    bool bNewBar=false;
    string uType;
    bool bRetval;
    string s;
    string uMess;

    fPY_ZMQ_CONTEXT_USERS=GlobalVariableGet("fPyZmqContextUsers");
    if (fPY_ZMQ_CONTEXT_USERS < 0.5) {
	vWarn("OnTick: no context users");
        return;
    }
    iCONTEXT = MathRound(GlobalVariableGet("fPyZmqContext"));
    if (iCONTEXT < 1) {
	vWarn("OnTick: unallocated context");
        return;
    }

    // same as Time[0]
    datetime tTime=iTime(uSYMBOL, iTIMEFRAME, 0);
    string sTime = TimeToStr(tTime, TIME_DATE|TIME_MINUTES) + " ";

    if (tTime != tNextbartime) {
        iBar += 1; // = Bars - 100
	bNewBar=true;
	iTick=0;
	uType="bar";
	tNextbartime=tTime;
	s=sBarInfo();
    } else {
        bNewBar=false;
	iTick+=1;
	uType="tick";
	s=iTick;
    }

    uMess  = iACCNUM +"|" +uSYMBOL +"|" +iTIMEFRAME +"|" + Bid +"|" + Ask +"|" + s +"|" + sTime;

    uRetval = uPySafeEval(uCHART_NAME+".eSendOnSpeaker('" +uType +"', '" +uMess +"')");
    if (StringFind(uRetval, "ERROR:", 0) >= 0) {
	uRetval = "ERROR: eSendOnSpeaker " +uType +" failed: "  + uRetval;
	vWarn("OnTick: " +uRetval);
	return;
    }
    // the retval should be empty - otherwise its an error
    if (uRetval == "") {
	vDebug("OnTick: " +uRetval);
    } else {
	vWarn("OnTimer: " +uRetval);
    }
}

void OnDeinit(const int iReason) {
    //? if (iReason == INIT_FAILED) { return ; }
    EventKillTimer();
    
    fPY_ZMQ_CONTEXT_USERS=GlobalVariableGet("fPyZmqContextUsers");
    if (fPY_ZMQ_CONTEXT_USERS < 1.5) {
	iCONTEXT = MathRound(GlobalVariableGet("fPyZmqContext"));
	if (iCONTEXT < 1) {
	    vWarn("OnDeinit: unallocated context");
	} else {
	    vPyExecuteUnicode("ZmqChart.oCONTEXT.destroy()");
	    vPyExecuteUnicode("ZmqChart.oCONTEXT = None");
	}
	GlobalVariableDel("fPyZmqContext");

	GlobalVariableDel("fPyZmqContextUsers");
	vDebug("OnDeinit: deleted fPyZmqContextUsers");
	
	vPyDeInit();
    } else {
	fPY_ZMQ_CONTEXT_USERS -= 1.0;
	GlobalVariableSet("fPyZmqContextUsers", fPY_ZMQ_CONTEXT_USERS);
	vDebug("OnDeinit: decreased, value of fPyZmqContextUsers to: " + fPY_ZMQ_CONTEXT_USERS);
    }
    

}
