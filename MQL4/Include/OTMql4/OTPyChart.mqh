// -*-mode: c; c-style: stroustrup; c-basic-offset: 4; coding: utf-8-dos -*-

/*
This will provide the interface from Mql to our Chart class in Python.

*/

#property copyright "Copyright 2014 Open Trading"
#property link      "https://github.com/OpenTrading/"
#property library

#import "OTMql4/OTPyChart.ex4"

string eSendOnSpeaker(string uChartId, string uType, string uMess);

string eReturnOnSpeaker(string uChartId, string uType, string uMess, string uOriginCmd);
