# OTMql4Py
## Open Trading Metaquotes4 Python Bridge

### OTMql4Py - MQL4 bindings for Python

Based in work by Bernard Kreuss
https://sites.google.com/site/prof7bit/metatrader-python-integration

with contributions by C. Polymeris 
http://chiselapp.com/user/polymeris/repository/metatraderpy/index

**This is a work in progress - a pre-developers version.**

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
not overwrite any system files.

You already should have the python27.dll and any other Python dlls
that you will call (e.g. pythoncom27.dll pythoncomloader27.dll pywintypes.dll)
installed into your windows system folder (e.g. c:\windows\system32)

You may have to set the environment variable PYTHONHOME to the root
of you Python installation (e.g. c:\Python27 ).

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
please post a message to say this project is now on github.com.

