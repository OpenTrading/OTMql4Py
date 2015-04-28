# OTMql4Py
## Open Trading Metaquotes4 Python Bridge

### OTMql4Py - MQL4 bindings for Python
https://github.com/OpenTrading/OTMql4Py/

Based in work by Bernd Kreuss
https://sites.google.com/site/prof7bit/metatrader-python-integration

with contributions by C. Polymeris 
http://chiselapp.com/user/polymeris/repository/metatraderpy/index

**This is a work in progress - a developers' pre-release version.**

It works well on builds > 6xx, but the documentation of the changes to the
original code still need writing, as well as more tests and testing on
different versions. Only Python 2.7.x is supported.

The project wiki should be open for editing by anyone logged into GitHub:
**Please report any system it works or doesn't work on in the wiki:
include the Metatrader build number, the origin of the metatrader exe,
the Windows version, and the Python version and origin of the Python.**
This code in known to run under Linux Wine (1.7.x), so this project
bridges Metatrader to Python under Linux.

### Installation

For the moment there is no installer: just "git clone" or download the
zip from github.com and unzip into an empty directory. Then recursively copy
the folder MQL4 over the MQL4 folder of your Metatrader installation. It will
not overwrite any Mt4 system files.

You already should have the python27.dll and any other Python dlls
that you will call (e.g. `pythoncom27.dll` `pythoncomloader27.dll` `pywintypes.dll`)
installed into your windows system folder (e.g. `c:\windows\system32`)

You may have to set the environment variable PYTHONHOME to the root
of your Python installation (e.g. `c:\Python27` ).

### Source

The source code to generate the py27.dll are in the src directory.
The sources have minor fixes to the original code other than the py26 -> py27
syntactic conversion, and still need recompiling: the dll checked-in at the
moment is from:
http://chiselapp.com/user/polymeris/repository/metatraderpy/index


### Project

Please file any bugs in the issues tracker:
https://github.com/OpenTrading/OTMql4Py/issues

Use the Wiki to start topics for discussion:
https://github.com/OpenTrading/OTMql4Py/wiki
It's better to use the wiki for knowledge capture, and then we can pull
the important pages back into the documentation in the share/doc directory.
You will need to be signed into github.com to see or edit in the wiki.

If you know of any threads in the forums that discuss this code,
please post a message to say this project is now on github.com at
https://github.com/OpenTrading/OTMql4Py/
## OTMql4Py Notes

### Changes

OTMql4Py has some changes to how the compiled dll code is used,
and includes a Python file `OTMql427.py` with extra functionality.

#### Unicode Functions

Build 600 of Metatrader4 changed the definition of the fundamental datatype
`string` from being ASCII to being Unicode, and broke every compiled
library called by Mt4 that send or received a string. The basic change
with implemented as a minor patch release rolled out on live systems.

Metaquotes should have left the existing string definition to be ASCII,
and introduced a new `unicode` datatype, along with Unicode aware functions,
usually with the same function name, but with a `W` appended, like Windows
does. You can still use ASCII strings in Metatrader4 >600: they are simply
arrays of `uchar`, and there are conversion functions such as
`StringToCharArray`. 

 
#### Initialization Code

The initialization code `iPyInit` in `MQL4/Include/OTMql4/OTPy27.mqh`
initializes the Python environment. This should be called from your
`OnInit()` function. It is safe to call it a second time; subsequent
calls will just be ignored.

It has an integer return value, and should return 0. 
A return value of -1 is a panic: remove the expert if it requires Python.

It calls the compiled `PyInitialize()` and then imports some standard
system modules. Then it prepends the `sys.path` with the directory
`MQL4/Python`, which should have been created when you installed `OTMql4Py`.
In that directory should be a (possibly empty) file `__init__.py`, so
that you can import modules found in that directory into Python.

The intialization code will import the module `OTMql427` found in that directory
to give some added functionality. If it can't import the module `OTMql427`
it will signal a panic by returning -1: you should fix the problem before
going any futher.

#### Global Variables

The `iPyInit` initialization creates a temporary global veriable called
`fPythonUsers` and increments it by one each time it is called.
`vPyDeInit` decrements it by one each time it is called, and if `fPythonUsers`
is zero, then it calls `OTMql427.vPyDeInit` to unload the Python interpreter.
`fPythonUsers` should always be equal to the number of charts and scripts
Python is being used on. Unfortunately, if your recompile your expert
while Python is loaded, then Mt4 will deinit your expert and re-init the
expert. If you only had one chart using Python (fPythonUsers=1), then
this will unload Python when Mt4 deinits the expert, and when Mt4 re-inits
the Python, it will fail to initialize the `py27.dll` properly. If Mt4
`OnInit` had a required `reason` argument the way `OnDeinit` does, we
could work around this, but it doesn't. Suggestions welcome...

The `iPyInit` initialization also creates a persistent global veriable called
"fDebugLevel" which is used by the logging code, and it ranges from 0 to 5:
0 : quiet, 1 : +errors, 2 : +warnings, 3 = +info, 4 : +debug, 5 : +trace.

#### Added Python Functionality

In many cases, you should use `uPySafeEval` to evaluate a python
expression that will evaluate to a string and return its value. It calls
`OTMql427.sPySafeEval` in Python which wraps the code to be evaluated
in a `try:/except:` clause and catches the error. If there's an error,
the error is returned as a string, prepended with `ERROR: `.

In the caller you should have something like:
    if (StringFind(uSource, "ERROR:", 0) == 0) {
      Print("Error in Python evaluating: " + uSource + "\n" + res);
      <do something as a result of the failure>
    }


### Testing

There are some initial tests in the file
`MQL4/Scripts/OTMql4/OTMql4PyTest.mq4`
Attach this script to a chart and it will run a series of simple tests;
you can choose which tests to run as inputs when you attach the script.
Look at the Experts log window for messages; errors will start with the
word `ERROR:` and should pop up a MessageBox.


### Known Issues

During testing, we have noticed an error when you are repeatedly
initilizing and uninitializing the Python interpreter. Any call of
Python generates a `exceptions.SystemError`. You must restart
Metatrader if this happens.



### Mt4 and Python Architecture

Mt4 runs an expert attached to a chart in a thread.
Python in a Mt4 expert starts a main thread that is unique to the
application, and starts another worker thread. The main thread is blocked
until Python is unloaded, and everything takes place in the worker thread.
The worker thread can start more threads.

You can send commands from Mt4 to Python, but Python can't send commands
to Mt4. So what you can do is queue up things for Mt4 to do, and
periodically get Mt4 to ask Python if it has anything it wants Mt4 to do.
It's easiest to think of registering an EventTimer with your expert, and
to have `OnTimer` function periodically ask Python if it has any work.
(Remember that `EventTimer` events fire even if the market is closed or
you have no connection, unlike `OnTick` events.)

The problem is that Mt4 does not have an `Eval` command, so if Python wants
Mt4 to do something, like `OrderSend`, we can't just pass a string to Mt4
that says `OrderSend(...)` and expect Mt4 to eval it. So what we have done
is write a simplistic replacement to what should be an `Eval` command in
Mt4, that will parse as string and execute it. See that function
`zMt4LibProcessCmd` in `MQL4/Libraries/OTMql4/OTLibMt4ProcessCmd.mq4`
of  the `OTMql4Lib` package (https://github.com/OpenTrading/OTMql4Lib/).
See also `OTLibProcessCmd.mq4` for an example of how to extend
`zMt4LibProcessCmd` to process your own functions.

This is not a proper replacement to an `Eval` function. It only executes
commands that it knows about, and has no ability to decipher complex commands.
Still, it allows Python to make decisions and ask Mt4 to do things,
which is enough for order and account processing. You can use this for
bi-directional interaction with a program outside of Mt4. For example,
you could use a call from `OnTick` into Python to send tick and bar info
to another program, and then use a call from `OnTimer` into Python to
ask if there are any requests back from the program that it wants Mt4
to evaluate.

You may also want to use threads and queues within Python to make sure
that any command that you ask Python to execute is accomplished within
the time it takes to get the next tick: programming with Python iterators
is probably a good idea. It is untested as to whether
the Python code dispatched from `OnTick` can block the chart or not.
