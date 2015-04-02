library py27;

{$mode objfpc}{$H+}

uses
  dynlibs, classes, sysutils, windows;

const
  PyDllName = 'python26.dll';
  Py_Eval_Input = 258;


type
  TGILState = Integer;
  TPyObject = record
                ob_refcnt : Integer;
                ob_type : Pointer;
              end;
  PPyObject = ^TPyObject;

  TInterpreterThread = class(TThread)
                         procedure Execute; override;
                       end;

var
  PyStatus : byte; // O: virgin 1: initializing 2: initialized
  Pydll : THandle;

  Py_Initialize : procedure(); cdecl;
  Py_Finalize : procedure(); cdecl;
  PyEval_InitThreads : procedure(); cdecl;
  PyGILState_Ensure : function() : TGILState; cdecl;
  PyGILState_Release : procedure(gstate : TGILState); cdecl;
  PyObject_Free : procedure(obj : PPyObject); cdecl;
  PyRun_SimpleString : function(code : PChar) : Integer; cdecl;
  PyRun_String : function(code : PChar; start : Integer; globals : PPyObject; locals : PPyObject) : PPyObject; cdecl;
  PyImport_AddModule : function(name : PChar) : PPyObject; cdecl;
  PyModule_GetDict : function(module : PPyObject) : PPyObject; cdecl;
  PyDict_GetItemString : function(dict : PPyObject; name : PChar) : PPyObject; cdecl;
  PyInt_AsLong : function(item : PPyObject) : Integer; cdecl;
  PyInt_FromLong : function(value : Integer) : PPyObject; cdecl;
  PyString_AsString : function(item : PPyObject) : PChar; cdecl;
  PyString_FromString : function(str : PChar) : PPyObject; cdecl;
  PyFloat_AsDouble : function(item : PPyObject) : Double; cdecl;
  PyFloat_FromDouble : function(value : Double) : PPyObject; cdecl;
  PyList_GetItem : function(list : PPyObject; index : Integer) : PPyObject; cdecl;
  PyList_Append : function(list : PPyObject; item : PPyObject) : Integer; cdecl;
  PyList_Size : function(list : PPyObject) : Integer; cdecl;

procedure LoadPyDll();
var
  // i don't want to type GetProcedureAddress() for every function
  p : function(d : THandle; n : ansistring) : Pointer; register;
begin
  Pointer(p) := @GetProcedureAddress;
  Pydll := LoadLibrary(PyDllName);
  if Pydll <> NilHandle then
  begin
    Pointer(Py_Initialize)        := p(Pydll, 'Py_Initialize');
    Pointer(Py_Finalize)          := p(Pydll, 'Py_Finalize');
    Pointer(PyEval_InitThreads)   := p(Pydll, 'PyEval_InitThreads');
    Pointer(PyGILState_Ensure)    := p(Pydll, 'PyGILState_Ensure');
    Pointer(PyGILState_Release)   := p(Pydll, 'PyGILState_Release');
    Pointer(PyObject_Free)        := p(Pydll, 'PyObject_Free');
    Pointer(PyRun_SimpleString)   := p(Pydll, 'PyRun_SimpleString');
    Pointer(PyRun_String)         := p(Pydll, 'PyRun_String');
    Pointer(PyImport_AddModule)   := p(Pydll, 'PyImport_AddModule');
    Pointer(PyModule_GetDict)     := p(Pydll, 'PyModule_GetDict');
    Pointer(PyDict_GetItemString) := p(Pydll, 'PyDict_GetItemString');
    Pointer(PyInt_AsLong)         := p(Pydll, 'PyInt_AsLong');
    Pointer(PyInt_FromLong)       := p(Pydll, 'PyInt_FromLong');
    Pointer(PyString_AsString)    := p(Pydll, 'PyString_AsString');
    Pointer(PyString_FromString)  := p(Pydll, 'PyString_FromString');
    Pointer(PyFloat_AsDouble)     := p(Pydll, 'PyFloat_AsDouble');
    Pointer(PyFloat_FromDouble)   := p(Pydll, 'PyFloat_FromDouble');
    Pointer(PyList_GetItem)       := p(Pydll, 'PyList_GetItem');
    Pointer(PyList_Append)        := p(Pydll, 'PyList_Append');
    Pointer(PyList_Size)          := p(Pydll, 'PyList_Size');
  end
  else
  begin
    MessageBox(
      0,
      PyDllName + ' could not be loaded.'#13#13
      + 'Make sure you have the correct Python version installed and have'#13
      + 'it installed "for all users" so ' + PyDllName + ' is in the system32 folder.',
      'Metatrader Python Interface',
      MB_ICONERROR
    )
  end;
end;

procedure unloadPyDll();
var
  gs : TGILState;
begin
  // stop the other thread by letting the infinite sleep loop end
  gs := PyGILState_Ensure();
  PyRun_SimpleString('__mt4dll__ = False');
  PyGILState_Release(gs);
  Sleep(200);

  // we should now be single threaded again

  Py_Finalize();
  if not UnloadLibrary(Pydll) then
  begin
    MessageBox(
      0,
      'The Python interpreter could not be unloaded for some reason.'#13
      + 'A crash is imminent! You should restart Metatrader!',
      'Metatrader Python Interface',
      MB_ICONERROR
    );
  end;
end;

procedure TInterpreterThread.Execute();
begin
  // this will be the one and only main thread for the Python interpreter
  Py_Initialize();
  PyEval_InitThreads();
  PyRun_SimpleString('import time');
  PyRun_SimpleString('__mt4dll__ = True');
  PyStatus := 2;

  // keep all CPU time of this system thread inside the python interpreter
  // by letting the main thread sleep until infinity so python
  // keeps running while effectvely doing nothing and thus always has CPU
  // time to keep all additional Python threads running that may be started
  // later
  PyRun_SimpleString('while __mt4dll__: time.sleep(0.1)');
end;


function PyIsInitialized() : Boolean; stdcall;
begin
  PyIsInitialized := (PyStatus = 2);
end;


procedure PyInitialize(); stdcall;
begin
  if PyStatus = 0 then
  begin
    // start the interpreter thread
    PyStatus := 1;
    TInterpreterThread.Create(False);
  end;

  // wait until it has reached the point where we can use it
  repeat
    Sleep(100);
  until PyIsInitialized();
end;


procedure PyDecRef(obj : PPyObject); stdcall;
var
  gs : TGILState;
begin
  gs := PyGILState_Ensure();
  obj^.ob_refcnt -= 1;
  if obj^.ob_refcnt = 0 then
  begin
    PyObject_Free(obj);
  end;
  PyGILState_Release(gs);
end;


procedure PyIncRef(obj : PPyObject); stdcall;
var
  gs : TGILState;
begin
  gs := PyGILState_Ensure();
  obj^.ob_refcnt += 1;
  PyGILState_Release(gs);
end;


function PyMainDict() : PPyObject; stdcall;
var
  gs : TGILState;
begin
  gs := PyGILState_Ensure();
  PyMainDict := PyModule_GetDict(PyImport_AddModule('__main__'));
  PyGILState_Release(gs);
end;


procedure PyExecute(code : PChar); stdcall;
var
  gs : TGILState;
begin
  gs := PyGILState_Ensure();
  PyRun_SimpleString(code);
  PyGILState_Release(gs);
end;


function PyEvaluate(code : PChar) : PPyObject; stdcall;
var
  gs : TGILState;
begin
  gs := PyGILState_Ensure();
  PyEvaluate := PyRun_String(code, Py_Eval_Input, PyMainDict(), PyMainDict());
  PyGILState_Release(gs);
end;


function PyLookupDict(dict : PPyObject; name : PChar) : PPyObject; stdcall;
var
  gs : TGILState;
begin
  gs := PyGILState_Ensure();
  pyLookupDict := PyDict_GetItemString(dict, name);
  PyGILState_Release(gs);
end;


function PyLookupList(list : PPyObject; index : Integer) : PPyObject; stdcall;
var
  gs : TGILState;
begin
  gs := PyGILState_Ensure();
  PyLookupList := PyList_GetItem(list, index);
  PyGILState_Release(gs);
end;


function PyGetInt(item : PPyObject) : Integer; stdcall;
var
  gs : TGILState;
begin
  gs := PyGILState_Ensure();
  PyGetInt := PyInt_AsLong(item);
  PyGILState_Release(gs);
end;


function PyGetDouble(item : PPyObject) : Double; stdcall;
var
  gs : TGILState;
begin
  gs := PyGILState_Ensure();
  PyGetDouble := PyFloat_AsDouble(item);
  PyGILState_Release(gs);
end;


function PyGetString(item : PPyObject) : PChar; stdcall;
var
  gs : TGILState;
begin
  gs := PyGILState_Ensure();
  PyGetString := PyString_AsString(item);
  PyGILState_Release(gs);
end;


function PyNewInt(value : Integer) : PPyObject; stdcall;
var
  gs : TGILState;
begin
  gs := PyGILState_Ensure();
  PyNewInt := PyInt_FromLong(value);
  PyGILState_Release(gs);
end;


function PyNewDouble(value : Double) : PPyObject; stdcall;
var
  gs : TGILState;
begin
  gs := PyGILState_Ensure();
  PyNewDouble := PyFloat_FromDouble(value);
  PyGILState_Release(gs);
end;


function PyNewString(value : PChar) : PPyObject; stdcall;
var
  gs : TGILState;
begin
  gs := PyGILState_Ensure();
  PyNewString := PyString_FromString(value);
  PyGILState_Release(gs);
end;


procedure PyListAppend(list : PPyObject; item : PPyObject) ; stdcall;
var
  gs : TGILState;
begin
  gs := PyGILState_Ensure();
  PyList_Append(list, item);
  PyGILState_Release(gs);
end;


function PyListSize(list : PPyObject) : Integer; stdcall;
var
  gs : TGILState;
begin
  gs := PyGILState_Ensure();
  PyListSize := PyList_Size(list);
  PyGILState_Release(gs);
end;


exports
  PyInitialize,
  PyIsInitialized,
  PyDecRef,
  PyIncRef,

  PyExecute,
  PyEvaluate,

  PyMainDict,
  PyLookupDict,
  PyLookupList,

  PyGetInt,
  PyGetDouble,
  PyGetString,

  PyNewInt,
  PyNewDouble,
  PyNewString,

  PyListAppend,
  PyListSize;

{$IFDEF WINDOWS}{$R py27.rc}{$ENDIF}

initialization
  PyStatus := 0;
  LoadPyDll();
finalization
  UnloadPyDll();
end.


