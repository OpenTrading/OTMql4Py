// -*-mode: c; c-style: stroustrup; c-basic-offset: 4; coding: utf-8-dos -*-

/*
This will provide our logging functions that work with Python.
See OTLibLog for just a skeleton logging.
*/

#property copyright "Copyright 2014 Open Trading"
#property link      "https://github.com/OpenTrading/"

// constants
#define LOG_PANIC 0 // unused
#define LOG_ERROR 1
#define LOG_WARN 2
#define LOG_INFO 3
#define LOG_DEBUG 4
#define LOG_TRACE 5

#define LOG_MAX 5

#import "OTMql4/OTLibPyLog.ex4"

void vSetLogLevel(int i);
int iGetLogLevel();
void vLog(int iLevel, string sMsg);

