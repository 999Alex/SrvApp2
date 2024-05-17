unit AddInLib;

{ V7 AddIn 2.0 Type Library }
{ Version 2.0 }

interface

uses Windows, ActiveX, Classes, Graphics, OleCtrls, StdVCL;

const
     IID_IInitDone : TIID = '{AB634001-F13D-11D0-A459-004095E1DAEA}';
     IID_IPropertyProfile : TIID = '{AB634002-F13D-11D0-A459-004095E1DAEA}';
     IID_ILanguageExtender : TIID = '{AB634003-F13D-11D0-A459-004095E1DAEA}';
     IID_IAsyncEvent : TIID = '{AB634004-F13D-11D0-A459-004095E1DAEA}';
     IID_IStatusLine : TIID = '{AB634005-F13D-11D0-A459-004095E1DAEA}';
     IID_IErrorLog : TIID = '{3127CA40-446E-11CE-8135-00AA004BB851}';
     IID_IExtWndsSupport: TGUID = '{EFE19EA0-09E4-11D2-A601-008048DA00DE}';

     IID_IPropertyLink : TIID = '{B59789E1-2E8B-11d1-A4E7-004095E1DAEA}';
type

{ Forward declarations: Interfaces }
  IInitDone = interface;
  ILanguageExtender = interface;
  IPropertyProfile = interface;
  IAsyncEvent = interface;
  IStatusLine = interface;

  RECT = packed record
    left: Integer;
    top: Integer;
    right: Integer;
    bottom: Integer;
  end;
//------------------------------------------------------------------------------
// VK 1c
//------------------------------------------------------------------------------
  // IInitDone Interface
  IInitDone = interface(IUnknown)
    ['{AB634001-F13D-11D0-A459-004095E1DAEA}']
    function Init(pConnection: IDispatch): HResult; stdcall;
    function Done: HResult; stdcall;
    function GetInfo(var pInfo: PSafeArray{(OleVariant)}): HResult; stdcall;
  end;
  // ILanguageExtender Interface
  ILanguageExtender = interface(IUnknown)
    ['{AB634003-F13D-11D0-A459-004095E1DAEA}']
    function RegisterExtensionAs(var bstrExtensionName: WideString): HResult; stdcall;
    function GetNProps(var plProps: Integer): HResult; stdcall;
    function FindProp(const bstrPropName: WideString; var plPropNum: Integer): HResult; stdcall;
    function GetPropName(lPropNum, lPropAlias: Integer; var pbstrPropName: WideString): HResult; stdcall;
    function GetPropVal(lPropNum: Integer; var pvarPropVal: OleVariant): HResult; stdcall;
    function SetPropVal(lPropNum: Integer; var varPropVal: OleVariant): HResult; stdcall;
    function IsPropReadable(lPropNum: Integer; var pboolPropRead: Integer): HResult; stdcall;
    function IsPropWritable(lPropNum: Integer; var pboolPropWrite: Integer): HResult; stdcall;
    function GetNMethods(var plMethods: Integer): HResult; stdcall;
    function FindMethod(const bstrMethodName: WideString; var plMethodNum: Integer): HResult; stdcall;
    function GetMethodName(lMethodNum, lMethodAlias: Integer; var pbstrMethodName: WideString): HResult; stdcall;
    function GetNParams(lMethodNum: Integer; var plParams: Integer): HResult; stdcall;
    function GetParamDefValue(lMethodNum, lParamNum: Integer; var pvarParamDefValue: OleVariant): HResult; stdcall;
    function HasRetVal(lMethodNum: Integer; var pboolRetValue: Integer): HResult; stdcall;
    function CallAsProc(lMethodNum: Integer; var paParams: PSafeArray{(OleVariant)}): HResult; stdcall;
    function CallAsFunc(lMethodNum: Integer; var pvarRetValue: OleVariant; var paParams: PSafeArray{(OleVariant)}): HResult; stdcall;
  end;
  // IPropertyProfile Interface
  IPropertyProfile = interface(IPropertyBag)
    ['{AB634002-F13D-11D0-A459-004095E1DAEA}']
    procedure RegisterProfileAs(const bstrProfileName: WideString); safecall;
  end;
  // IAsyncEvent Interface
  IAsyncEvent = interface(IUnknown)
    ['{AB634004-F13D-11D0-A459-004095E1DAEA}']
    procedure SetEventBufferDepth(lDepth: Integer); safecall;
    procedure GetEventBufferDepth(var plDepth: Integer); safecall;
    procedure ExternalEvent(const bstrSource, bstrMessage, bstrData: WideString); safecall;
    procedure CleanBuffer; safecall;
  end;
  // IStatusLine Interface
  IStatusLine = interface(IUnknown)
    ['{AB634005-F13D-11D0-A459-004095E1DAEA}']
    procedure SetStatusLine(const bstrSource: WideString); safecall;
    procedure ResetStatusLine; safecall;
  end;
  // IExtWndsSupport Interface
  IExtWndsSupport = interface(IUnknown)
    ['{EFE19EA0-09E4-11D2-A601-008048DA00DE}']
    function GetAppMainFrame(var hwnd: HWND): HResult; stdcall;
    function GetAppMDIFrame(var hwnd: HWND): HResult; stdcall;
    function CreateAddInWindow(const bstrProgID: WideString; const bstrWindowName: WideString;
                             dwStyles: Integer; dwExStyles: Integer; var rctl: RECT;
                             Flags: Integer; var pHwnd: HWND; var pDisp: IDispatch): HResult; stdcall;
  end;
//------------------------------------------------------------------------------
implementation

initialization
end.
