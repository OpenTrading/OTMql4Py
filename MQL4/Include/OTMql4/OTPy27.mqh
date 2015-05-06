// -*-mode: c; c-style: stroustrup; c-basic-offset: 4; coding: utf-8-dos -*-
//+------------------------------------------------------------------+
//|                                                         py27.mqh |
//|                                                     Bernd Kreuss |
//|                                             mailto:7ibt@arcor.de |
//|                                                                  |
//|                                                                  |
//|               Python Integration For Metatrader 4                |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Bernd Kreuss and Open Trading"
#property link      "https://github.com/OpenTrading/"

/*
   You should not use any of these functions directly:
   use Libraries/OTMql4/OTLibPy.mq4 instead, which
   are wrappers around these funtions that use unicode strings.
*/

#import "kernel32.dll"
int lstrlenA(int);
void RtlMoveMemory(uchar & arr[], int, int);
int LocalFree(int); // May need to be changed depending on how the DLL allocates memory
#import


/*
   Be careful of using any of these imported funtions directly for strings:
   they expect uchar[] arrays, not unicode strings.
*/

#import "OTMql4/py27.dll" // dll version 1.3.0.x (for Python 2.7.x)

/**
 * Initialize the Python environmant. This will start a new
 * thread which will initialize Python and enter a sleep() loop.
 * Dont call this directly, call PyInit() instead. (see below)
 */
void PyInitialize();

/**
 * Return True if PyInitialize() has already been called
 */
bool PyIsInitialized();

/**
 * Decrease the reference counter of a Python object by one and free the
 * object if the counter reaches zero. You may only call this for objects
 * that you OWN yourself, not for BORROWED references.
 */
void PyDecRef(int p_object);

/**
 * Increase the reference counter by one
 */
void PyIncRef(int p_object);

/**
 * Execute an arbitrary piece of python code
 */
/* was: void PyExecute(string uSource); */
void PyExecute(uchar &uSource[]);


/**
 * Evaluate a python expression and return your NEW OWN
 * reference to the result. For example if foo.bar.baz is a list
 * and you want a reference to it so you can directy loop through
 * its members then just call PyEvaluate("foo.bar.baz") and use
 * the return value as a handle for the PyLookupList() function.
 * You can also use this handle for PyListAppend() because it is
 * *not* a copy but rather a reference to the original list.
 *
 * After you are done with using the handle returned by PyEvaluate()
 * you MUST call PyDecRef() to signal Python that you are now done
 * with this object, this will restore the reference counter to
 * the value it had before or free it completely if the object
 * was created by the code you evaled (return value of a function
 * or the result of a calculation which python will no longer
 * need after you read it)
 */
// new reference, PyDecRef() after using!
/* was: int PyEvaluate(string uSource); */
int PyEvaluate(uchar &uSource[]);

/**
 * return a BORROWED reference to the __main__ dict
 */
int PyMainDict();

/**
 * return a BORROWED reference to the item in the dict
 * specified by name.
 */
/* was:int PyLookupDict(int p_dict, string name);*/
int PyLookupDict(int p_dict, uchar &name[]);

/**
 * return a BORROWED reference to the item in the list
 * specified by index.
 */
int PyLookupList(int p_list, int index);

/**
 * return the value of the object as int
 * (if it is a numeric object)
 */
int PyGetInt(int ptr_int);

/**
 * return the value of the object as a double
 * (if it is a numeric object)
 */
double PyGetDouble(int p_double);

/**
 * return the value of the object as a string
 * (only if it actually is a string object)
 */
/* was: string PyGetString(int p_string);*/
int PyGetString(int p_string);

/**
 * create a new integer obect. You will OWN a reference,
 * so take care of the reference counter
 */
int PyNewInt(int value);

/**
 * create a new double (actually a python float) object.
 * You will OWN a reference, so take care of the reference counter
 */
int PyNewDouble(double value);

/**
 * create a new string obect. You will OWN a reference,
 * so take care of the reference counter
 */
/* was: int PyNewString(string &value);
   FixMe: this is a pointer to a string:
   how do we do a pointer to a uchar[] pointer?
*/
int PyNewString(uchar &value[]);


/**
 * append the item to the list. This function will NOT steal
 * the reference, it will create its own, so ownership
 * will not change, so if it was your OWN and NOT a
 * borrowed reference you must decref after you are done
 */
void PyListAppend(int p_list, int p_item);

/**
 * return the size of the list object
 */
int PyListSize(int p_list);

#import

// string uPyGetUnicodeFromPointer(int p_string);
string uPyGetUnicodeFromPointer(int p_string) {
    int iPointer, iMessLen;
    string uMessage;
    uchar sCharArray[];

    iPointer = PyGetString(p_string);
    // Get the length of the string
    iMessLen = lstrlenA(iPointer);

    // if message length is 0, leave.
    if (iMessLen < 1) {
        return("");
    }

    // Create a uchar[] array whose size is the string length (plus null terminator)
    ArrayResize(sCharArray, iMessLen);

    // Use the Win32 API to copy the string from the block returned by the DLL
    // into the uchar[] array
    RtlMoveMemory(sCharArray, iPointer, iMessLen);
    // Convert the uchar[] array to a string
    uMessage = CharArrayToString(sCharArray);
    return(uMessage);
}
