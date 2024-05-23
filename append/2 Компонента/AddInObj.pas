unit AddInObj;

interface

uses ComServ, ComObj, ActiveX, AddInLib, SysUtils, Windows, ExtCtrls, Forms,
  StrUtils, Variants, idGlobal, idIOHandlerSocket, PropPage,  Classes, TypInfo,
  ShellAPI, Clipbrd,
  UMain, UObj, UMapFile, uLkJSON;

const
    { This GUID should be changed}
  CLSID_AddInObject : TGUID = '{A540EF01-EA5D-4757-A1E0-6D2A46C291FF}';
  CLSID_AddInRet    : TGUID = '{7CACB90E-88D6-4F8F-B3D5-C5A5C2E472B9}';
  CLSID_AddInTable  : TGUID = '{ABF5A5CB-14A9-44D6-AB2A-D9441D9C3C96}';
  CLSID_AddInJSON  : TGUID = '{A9105F79-3340-42E0-AB8F-977062258EEE}';

type
  TNamesArray = array of PWideChar;
  TDispIDsArray = array[0..0] of TDISPID;
  PDispIDsArray=^TDispIDsArray;
  aCols=array of WideString;
//------------------------------------------------------------------------------
TComObjectP=class (TComObject)
  PropertyVal: TPropertyArray;
end;
//------------------------------------------------------------------------------
TAddInObject = class (TComObjectP, IDispatch, IInitDone, ISpecifyPropertyPages,
                                        ILanguageExtender)
  // Interfaces
  pConnect : Variant;

  pErrorLog : IErrorLog;
  pEvent : IAsyncEvent;
  pProfile : IPropertyProfile;
  pStatusLine : IStatusLine;
  pExtWndsSupport: IExtWndsSupport; // ++

  tmrProc : TTimer;
  tmrLive : TTimer;
  tmrEC : TTimer;

  frmMain : TfrmMain; // ++
  aCmd:String;        // ++
  F1C : OLEVariant;   // ++ Контекст обработки из 1С 8, для 1С 7 - 0
  App:string;         // Версия 1С, '7', '8'

  Result_EC: AnsiString;  // Результат выполнения команды 1С 7, устанавливается в ОбработкеВешнегоСобытия

  // Interface implementation
  // IDispatch
  function GetIDsOfNames(const IID: TGUID; Names: Pointer;
    NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; virtual; stdcall;
  function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; virtual; stdcall;
  function GetTypeInfoCount(out Count: Integer): HResult; virtual; stdcall;
  function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
    Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; virtual; stdcall;
  // IInitDone implementation
  function Init(pConnection: IDispatch): HResult; stdcall;
  function Done: HResult; stdcall;
  function GetInfo(var pInfo: PSafeArray{(OleVariant)}): HResult; stdcall;
  // ISpecifyPropertyPages implementation }
  function GetPages(out Pages: TCAGUID) : HResult; stdcall;
  // This function is useful in ILanguageExtender implementation }
  function GetNParam(var pArray : PSafeArray; lIndex: Integer ): OleVariant;
  procedure PutNParam(var pArray: PSafeArray; lIndex: Integer; var varPut: OleVariant);
  // ILanguageExtender implementation }
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

  //

  procedure fAddLog(tStr:string); // ++

  function LoadProperties: Boolean;
  procedure SaveProperties;

  function CmdProc7(lCmd,lParam: AnsiString):AnsiString;
  function CmdProc7_1(lCmd,lParam: AnsiString):AnsiString;
  function CmdProc8(lCmd,lParam: AnsiString):AnsiString;
  procedure OnTmrProc(Sender: TObject);
  procedure OnTmrLive(Sender: TObject);
  procedure OnTmrEC(Sender: TObject);
  public
    fFileMap:tFileMap;
    AppTimeOut:integer;
    hMain:THandle;        // ++
    //lpBaseAddr:PAnsiChar; // ++
    //sTime:TDateTime;      // ++
    SessionIndex:word;

    flDelNPP: integer;    // Удалять неразрывные пробелы
    flDebugFile: integer; // Вывод отладочной информации в файл

  published

    function meth_Quit(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_Open(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_UpdActive(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_Enable(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_Disable(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;

    function meth_Connect(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_Disconnect(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_Send(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;

    function propGet_AppTimeOut(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function propSet_AppTimeOut(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function propGet_SocketTimeOut(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function propSet_SocketTimeOut(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;

    function meth_Result_EC(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;

    function meth_HTTPPost(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_GetClipBoardFile(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;

    function propGet_Log(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function propGet_Version(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_LogTop(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_LogClear(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;

    function meth_COM_Open(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_COM_Close(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_COM_Read(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_COM_ReadLN(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_COM_Write(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
end;

TAddInRet = class (TComObjectP, IDispatch)
  // IDispatch
  function GetIDsOfNames(const IID: TGUID; Names: Pointer;
    NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; virtual; stdcall;
  function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; virtual; stdcall;
  function GetTypeInfoCount(out Count: Integer): HResult; virtual; stdcall;
  function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
    Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; virtual; stdcall;
  // protected
  protected
    fTable:OLEVariant;
  // Публичные
  published
    function meth_Table(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_Table1C7(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
end;

TAddInTable = class (TComObjectP, IDispatch)
    // IDispatch
  function GetIDsOfNames(const IID: TGUID; Names: Pointer;
    NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; virtual; stdcall;
  function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; virtual; stdcall;
  function GetTypeInfoCount(out Count: Integer): HResult; virtual; stdcall;
  function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
    Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; virtual; stdcall;
  // protected
  protected
    fRowCount,fColCount:Word;
    fCols:aCols;
    fCells:array of aCols;

  // Публичные
  published
    function meth_FromStr(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_Cells(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
end;

TAddInList = class (TComObjectP, IDispatch)
  // IDispatch
  function GetIDsOfNames(const IID: TGUID; Names: Pointer;
    NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; virtual; stdcall;
  function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; virtual; stdcall;
  function GetTypeInfoCount(out Count: Integer): HResult; virtual; stdcall;
  function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
    Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; virtual; stdcall;
  // protected
  protected
    fValue:OLEVariant;
  // Публичные
  published
    function meth_Val(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
end;

TAddInJSON = class (TComObjectP, IDispatch)
  // IDispatch
  function GetIDsOfNames(const IID: TGUID; Names: Pointer;
    NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; virtual; stdcall;
  function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; virtual; stdcall;
  function GetTypeInfoCount(out Count: Integer): HResult; virtual; stdcall;
  function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
    Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; virtual; stdcall;
  // protected
  protected
    fJSON:TlkJSONobject;
  // Публичные
  published
    function propGet_Text(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_Add(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
    function meth_Destroy(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
end;

//------------------------------------------------------------------------------
function vGetInfo(): string;
procedure AddLog(tStr:String);
//------------------------------------------------------------------------------
var
  AddIn :TAddInObject;
  COMPort:cardinal;
implementation
//------------------------------------------------------------------------------
function vGetInfo(): string;
type
  TVerInfo=packed record
    Nevazhno: array[0..47] of byte; // ненужные нам 48 байт
    Minor,Major,Build,Release: word; // а тут версия
  end;

var
  s:TResourceStream;
  v:TVerInfo;
begin
  result:='';
  try
    s:=TResourceStream.Create(HInstance,'#1',RT_VERSION); // достаём ресурс
    if s.Size>0 then begin
      s.Read(v,SizeOf(v)); // читаем нужные нам байты
      result:=IntToStr(v.Major)+'.'+IntToStr(v.Minor)+'.'+ // вот и версия...
              IntToStr(v.Release)+'.'+IntToStr(v.Build);
    end;
    s.Free;
  except;
  end;
end;
//------------------------------------------------------------------------------
procedure AddLog(tStr:String);
begin
  if Assigned(AddIn) then AddIn.fAddLog(tStr);
end;
//------------------------------------------------------------------------------
function doGetIDsOfNames(AObj:TObj; const IID: TGUID; Names: Pointer; NameCount: Integer; LocaleID: Integer; DispIDs: Pointer):HResult;
var
  lN:^TNamesArray;
  lName:String;
  i,j:integer;
begin
  lN:=@Names;
  lName:=String(lN^[0]);
  //MessageBox(0, PWideChar('*getids '+AObj.Name+'-'+lName), '', 0 );
  if NameCount<>1 then begin
    Result := E_NOTIMPL;
    exit;
  end;

  Result := S_OK;
  i:=0;
  while i<AObj.fIDs.Count do begin
    if (lName=TPropertyLib(AObj.fIDs[i]).Name1)or((lName=TPropertyLib(AObj.fIDs[i]).Name2)) then begin
      PDispIDsArray(DispIDs)[0]:=Integer(i);
      exit;
    end;
    inc(i);
  end;
  i:=0;
  while i<AObj.fIDs.Count do begin
    if (lName=TMethodLib(AObj.fIDs[i]).Name1)or((lName=TMethodLib(AObj.fIDs[i]).Name2)) then begin
      PDispIDsArray(DispIDs)[0]:=Integer(i);
      exit;
    end;
    inc(i);
  end;
  Result := DISP_E_UNKNOWNNAME;
end;
//------------------------------------------------------------------------------
function doInvoke(ASender:TComObjectP; AObj:TObj; DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word;
                          var Params; VarResult: Pointer; ExcepInfo: Pointer; ArgErr: Pointer):HResult;
var
  i, j:Integer;
  lI: TIDLib;
//  lM: TMethodLib;
  lP: TPropertyLib;
  lPVal:TPropertyVal;

  lF:TFunc;
  sParams:PSafeArray;
  v, lParams, ARet:OLEVariant;
  tv:tagVariant;
begin
  //AddIn.AddLog('Invoke '+inttostr(DispID)+' flags '+inttohex(Flags, 4));
  //MessageBox(0, PWideChar('*do invoke '+AObj.Name+' '+inttohex(Flags)+' '+inttostr(DispID)), '', 0 );
  if AObj.fIDs.Count>DispID then begin
    lI:=TMethodLib(AObj.fIDs.Items[DispID]);
    case Flags of
      DISPATCH_PROPERTYPUT:begin
        lP:=TPropertyLib(lI);
        if not lP.isWritable then begin
          Result := E_ACCESSDENIED;
          exit;
        end;

        AObj.GetPropVal(ASender.PropertyVal, lP.Name1).Val:=String(TDispParams(Params).rgvarg^[0].bstrVal);
      end;
      else begin // остальные варианты могут вызывать функцию
        // Определим адрес соответствующей функции
        case lI.tID of
          1: begin // вызов метода
            TMethod(lF).Code:=ASender.MethodAddress('meth_'+lI.Name1);
            TMethod(lF).Data:=ASender;
            if not Assigned(TMethod(lF).Code) then begin
              Result := E_OUTOFMEMORY;
              exit;
            end;

            i:=TDispParams(Params).cArgs;
            j:=0;
            lParams:=VarArrayCreate([0, i], varVariant);
            while i>0 do begin
              dec(i);
              tv:=TDispParams(Params).rgvarg^[i];
              //MessageBox(0, PWideChar('*m '+lI.Name1+' '+inttostr(tv.vt)), '', 0 );
              case tv.vt of
                VT_R8: lParams[j]:=tv.dblVal;
                VT_BSTR: lParams[j]:=String(tv.bstrVal);
                VT_BYREF or VT_VARIANT: lParams[j]:=tv.pvarVal^;
                VT_BYREF or VT_BSTR: lParams[j]:=tv.pbstrVal^;
              else
                //MessageBox(0, PWideChar('***m '+lI.Name1+' '+inttostr(tv.vt)), '', 0 );
              end;
              inc(j);
            end;
            sParams := PSafeArray(TVarData(lParams).VArray);
            lF(sParams, ARet);
            if Flags<>DISPATCH_METHOD then OLEVariant(VarResult^):=ARet;
          end;
          0: begin // вызов свойства
            TMethod(lF).Code:=ASender.MethodAddress('propGet_'+lI.Name1);
            TMethod(lF).Data:=ASender;

            lP:=TPropertyLib(lI);
            if not lP.isReadable then begin
              Result := E_ACCESSDENIED;
              exit;
            end;
            if Assigned(TMethod(lF).Code) then begin
              sParams := PSafeArray(TVarData(lParams).VArray);
              lF(sParams, ARet);
              OLEVariant(VarResult^):=ARet;
            end else begin
              //MessageBox(0, PWideChar('*p '+lP.Name1), '', 0 );
              OLEVariant(VarResult^):=AObj.GetPropVal(ASender.PropertyVal, lP.Name1).Val;
            end;

          end;
        end;

      end;
    end;

//      DISPATCH_PROPERTYGET:begin
//      end;
//    end;
//      DISPATCH_METHOD, DISPATCH_METHOD+DISPATCH_PROPERTYGET: begin // Функция
      //AddIn.AddLog('..func '+inttostr(DispID)+' paramcount '+inttohex(TDispParams(Params).cArgs,4));
//      end;
//    end;
  end;

  Result := S_OK;
end;
//------------------------------------------------------------------------------
// TlnExt_Ret
//------------------------------------------------------------------------------
function TAddInRet.GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount: Integer; LocaleID: Integer; DispIDs: Pointer):HResult;
begin
  Result:=doGetIDsOfNames(Ret, IID, Names, NameCount, LocaleID, DispIDs);
end;
//------------------------------------------------------------------------------
function TAddInRet.GetTypeInfo(Index: Integer; LocaleID: Integer; out TypeInfo):HResult;
begin
  //MessageBox(0, PWideChar('*RET.GetTypeInfo '+inttostr(index)), '', 0 );
  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInRet.GetTypeInfoCount(out Count: Integer):HResult;
begin
  //MessageBox(0, PWideChar('GetTypeInfoCount '), '', 0 );
  Count:=0;
  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInRet.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word;
                          var Params; VarResult: Pointer; ExcepInfo: Pointer; ArgErr: Pointer):HResult;
begin
  try
    //AddIn.AddLog('--- Table.Invoke ---');
    Result := doInvoke(Self, Ret, DispID, IID, LocaleID, Flags, Params, VarResult, ExcepInfo, ArgErr);
  except
    on E: Exception do begin
      AddLog('*** Ret.Invoke *'+E.Message);
    end;
  end;
end;
//------------------------------------------------------------------------------
function TAddInRet.meth_Table(paParams: PSafeArray; var ARet: OleVariant):HResult;
var
  lText:OLEVariant;
  lSepRow, lSepCol:WideString;
begin
  //MessageBox(0, PWideChar('*Ret.Table'), '', 0 );

  ARet:=ComObj.CreateOLEObject('AddIn.TlnExt5_Table');
//  if Ret.GetPropVal('Answer')=nil then begin
//    AddIn.AddLog('Answer nil !');
//    exit;
//  end;
  lText:=Ret.GetPropVal(PropertyVal, 'Answer').Val;
//  AddIn.AddLog('Table - Answer='+lText);
  lSepRow:=AddIn.GetNParam(paParams, 0);
  lSepCol:=AddIn.GetNParam(paParams, 1);
  //AddIn.AddLog('* Table '+inttostr(byte(lSepRow[1])));

  ARet.FromStr(lText, lSepRow, lSepCol);
  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInRet.meth_Table1C7(paParams: PSafeArray; var ARet: OleVariant):HResult;
var
  lText:OLEVariant;
  lPRow:word;
  lSepRow, lSepCol:WideString;
  ColCount:word;
  v77:OLEVariant;
  lRow:word;

  procedure AddRow(AText:WideString);
  var
    lPCol:word;
    lR:^aCols;
    ls:WideString;
    lCol:word;
  begin
    lCol:=0;
    lPCol:=Pos(lSepCol, AText);
    while lPCol>0 do begin
      inc(lCol);
      if ColCount<lCol then begin
        inc(ColCount);
        ARet.НоваяКолонка;
      end;

      //*ARet.УстановитьЗначение(double(lRow), double(lCol), LeftStr(AText, lPCol-1));
      //ARet.УстановитьЗначение(lRow, lCol, LeftStr(AText, lPCol-1));
      AText:=MidStr(AText, lPCol+1, Length(AText)-lPCol);
      lPCol:=Pos(lSepCol, AText);
    end;
    //if ColCount<lCol+1 then ColCount:=lCol+1;
  end;

begin
  try
    v77:=AddIn.pConnect.AppDispatch;
    IDispatch(v77)._AddRef;

    ARet:=v77.CreateObject('ТаблицаЗначений');
    lSepRow:=AddIn.GetNParam(paParams, 0);
    lSepCol:=AddIn.GetNParam(paParams, 1);
    lText:=Ret.GetPropVal(PropertyVal, 'Answer').Val+lSepRow;
    //AddIn.AddLog(' Ret.Table1C7 '+lText);

    ColCount:=0;
    lRow:=0;
    lPRow:=Pos(lSepRow, lText);
    while lPRow>0 do begin
      ARet.НоваяСтрока;
      inc(lRow);
      AddRow(LeftStr(lText, lPRow-1)+lSepCol);
      lText:=MidStr(lText, lPRow+1, Length(lText)-lPRow);
      lPRow:=Pos(lSepRow, lText);
    end;

  except
    on E: Exception do begin
      AddLog('*** Ret.Table1C7 *'+E.Message);
    end;
  end;
  Result := S_OK;
end;
//------------------------------------------------------------------------------
// TlnExt_Table
//------------------------------------------------------------------------------
function TAddInTable.GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount: Integer; LocaleID: Integer; DispIDs: Pointer):HResult;
begin
  Result:=doGetIDsOfNames(Table, IID, Names, NameCount, LocaleID, DispIDs);
end;
//------------------------------------------------------------------------------
function TAddInTable.GetTypeInfo(Index: Integer; LocaleID: Integer; out TypeInfo):HResult;
begin
  Result := E_NOTIMPL;
end;
//------------------------------------------------------------------------------
function TAddInTable.GetTypeInfoCount(out Count: Integer):HResult;
begin
  Count:=0;
  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInTable.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word; var Params; VarResult: Pointer; ExcepInfo: Pointer; ArgErr: Pointer):HResult;
begin
  try
    //AddIn.AddLog('--- Table.Invoke ---');
    Result := doInvoke(Self, Table, DispID, IID, LocaleID, Flags, Params, VarResult, ExcepInfo, ArgErr);
  except
    on E: Exception do begin
      AddLog('*** Table.Invoke *'+E.Message);
    end;
  end;
end;
//------------------------------------------------------------------------------
function TAddInTable.meth_FromStr(paParams: PSafeArray; var ARet: OleVariant):HResult;
var
  SepCol, SepRow:WideString;
  lPRow:word;
  lText:WideString;
  ld:word;
  varGet:OLEVariant;
  lPVal:TPropertyVal;

  procedure AddRow(AText:WideString);
  var
    lPCol:word;
    lR:^aCols;
    ls:WideString;
    lRow, lCol:word;
  begin
    lRow:=Length(fCells);
    SetLength(fCells, lRow+1);
    lR:=@fCells[lRow];
    lCol:=0;
    lPCol:=Pos(SepCol, AText);
    while lPCol>0 do begin
      lCol:=Length(lR^);
      SetLength(lR^, lCol+1);
      lR^[lCol]:=LeftStr(AText, lPCol-1)  ;
      AText:=MidStr(AText, lPCol+1, Length(AText)-lPCol);
      lPCol:=Pos(SepCol, AText);
    end;
    if lPVal.Val<lCol+1 then lPVal.Val:=lCol+1;
  end;

begin
//  AddIn.AddLog('*** FromStr ***');
//  AddIn.AddLog(AddIn.GetNParam(paParams, 0));
//  AddIn.AddLog(AddIn.GetNParam(paParams, 1));
//  AddIn.AddLog(AddIn.GetNParam(paParams, 2));

  SepRow:=AddIn.GetNParam(paParams, 1);
  SepCol:=AddIn.GetNParam(paParams, 2);
  lText:=AddIn.GetNParam(paParams, 0)+SepRow;
  lPVal:=Table.GetPropVal(PropertyVal, 'ColCount');
  lPVal.Val:=0;

  lPRow:=Pos(SepRow, lText);
  while lPRow>0 do begin
    AddRow(LeftStr(lText, lPRow-1)+SepCol);
    lText:=MidStr(lText, lPRow+1, Length(lText)-lPRow);
    lPRow:=Pos(SepRow, lText);
  end;
  Table.GetPropVal(PropertyVal, 'RowCount').Val:=Length(fCells);

//  AddIn.AddLog('*'+inttostr( Table.GetPropVal(PropertyVal, 'ColCount').Val));
end;
//------------------------------------------------------------------------------
function TAddInTable.meth_Cells(paParams: PSafeArray; var ARet: OleVariant):HResult;
var
  lR:^aCols;
  lRow,lCol:Word;
begin
  ARet:='';
  try
    lRow:=AddIn.GetNParam(paParams, 0);
    lCol:=AddIn.GetNParam(paParams, 1);

    //AddIn.AddLog('*** Cells ***'+inttostr(lRow));
    if lRow<Length(fCells) then begin
      lR:=@fCells[lRow];
      if lCol<Length(lR^) then begin
        ARet:=lR^[lCol];
        exit;
      end;
    end;
  except
    on E: Exception do begin
      AddLog('*** Cells *'+E.Message);
    end;
  end;
  Result := S_OK;
end;
//------------------------------------------------------------------------------
// TlnExt_List
//------------------------------------------------------------------------------
function TAddInList.GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount: Integer; LocaleID: Integer; DispIDs: Pointer):HResult;
begin
  Result:=doGetIDsOfNames(List, IID, Names, NameCount, LocaleID, DispIDs);
end;
//------------------------------------------------------------------------------
function TAddInList.GetTypeInfo(Index: Integer; LocaleID: Integer; out TypeInfo):HResult;
begin
  //MessageBox(0, PWideChar('*RET.GetTypeInfo '+inttostr(index)), '', 0 );
  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInList.GetTypeInfoCount(out Count: Integer):HResult;
begin
  //MessageBox(0, PWideChar('GetTypeInfoCount '), '', 0 );
  Count:=0;
  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInList.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word;
                          var Params; VarResult: Pointer; ExcepInfo: Pointer; ArgErr: Pointer):HResult;
begin
  try
    //AddIn.AddLog('--- Table.Invoke ---');
    Result := doInvoke(Self, List, DispID, IID, LocaleID, Flags, Params, VarResult, ExcepInfo, ArgErr);
  except
    on E: Exception do begin
      AddLog('*** List.Invoke *'+E.Message);
    end;
  end;
end;
//------------------------------------------------------------------------------
function TAddInList.meth_Val(paParams: PSafeArray; var ARet: OleVariant):HResult;

begin

end;
//------------------------------------------------------------------------------
// TlnExt_JSON
//------------------------------------------------------------------------------
function TAddInJSON.GetIDsOfNames(const IID: TGUID; Names: Pointer; NameCount: Integer; LocaleID: Integer; DispIDs: Pointer):HResult;
begin
  Result:=doGetIDsOfNames(JSON, IID, Names, NameCount, LocaleID, DispIDs);
end;
//------------------------------------------------------------------------------
function TAddInJSON.GetTypeInfo(Index: Integer; LocaleID: Integer; out TypeInfo):HResult;
begin
  //MessageBox(0, PWideChar('*RET.GetTypeInfo '+inttostr(index)), '', 0 );
  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInJSON.GetTypeInfoCount(out Count: Integer):HResult;
begin
  //MessageBox(0, PWideChar('GetTypeInfoCount '), '', 0 );
  Count:=0;
  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInJSON.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer; Flags: Word;
                          var Params; VarResult: Pointer; ExcepInfo: Pointer; ArgErr: Pointer):HResult;
begin
  try
    //AddIn.AddLog('--- Table.Invoke ---');
    Result := doInvoke(Self, JSON, DispID, IID, LocaleID, Flags, Params, VarResult, ExcepInfo, ArgErr);
  except
    on E: Exception do begin
      AddLog('*** JSON.Invoke *'+E.Message);
    end;
  end;
end;
//------------------------------------------------------------------------------
function TAddInJSON.meth_Add(paParams: PSafeArray; var ARet: OleVariant):HResult;
var
  lID:WideString;
  lVal:String;
begin
  try
    if not Assigned(fJSON) then fJSON:=TlkJSONobject.Create;
    lID:=AddIn.GetNParam(paParams, 0);
    lVal:=AddIn.GetNParam(paParams, 1);
    fJSON.Add( lID, lVal);
  except
    Result := S_FALSE
  end;

  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInJSON.meth_Destroy(paParams: PSafeArray; var ARet: OleVariant):HResult;
begin
  fJSON.Destroy;
end;
//------------------------------------------------------------------------------
function TAddInJSON.propGet_Text(paParams: PSafeArray; var ARet:OLEVariant): HResult;
begin
  try
    ARet:=TlkJSON.GenerateText(fJSON);
    
  except
    Result := S_FALSE
  end;

  Result := S_OK;
end;
//------------------------------------------------------------------------------
// TlnExt
//------------------------------------------------------------------------------
//procedure WriteFM(ADisp:word; AMsg:String);
////var
////  ls:^AnsiString;
//begin
////  ls:=@lpBaseAddr[ADisp];
////  ls^:=AMsg+#0;
//    StrPCopy(AddIn.lpBaseAddr+ADisp, AnsiString(AMsg)+#0);
//end;
//------------------------------------------------------------------------------
// TlnExt - IDispatch
//------------------------------------------------------------------------------
function TAddInObject.GetIDsOfNames(const IID: TGUID; Names: Pointer;
  NameCount, LocaleID: Integer; DispIDs: Pointer): HResult;
begin
  if AddIn=nil then AddIn:=Self;
  Result:=doGetIDsOfNames(Obj, IID, Names, NameCount, LocaleID, DispIDs);
end;
//------------------------------------------------------------------------------
function TAddInObject.GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult;
begin
  Result := E_NOTIMPL;
  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.GetTypeInfoCount(out Count: Integer): HResult;
begin
  Count:=0;
  //MessageBox(0, '*OBJ GetTypeInfoCount', '', 0 );
  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
  Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult;
var
  Res:OLEVariant;
begin
  try
//    try
//      Res:=ComObj.CreateOLEObject('AddIn.TlnExt5_Ret');
//      Res.Code:='250';
//    except on E:Exception do begin
//        AddLog('Ошибка: '+E.Message);
//        Res := '300 '+E.Message;
//        exit;
//      end;
//    end;
//    VarResult:=@Res;
//    Result:=S_OK;

    //AddLog('--- Obj.Invoke ---');
    Result := doInvoke(Self, Obj, DispID, IID, LocaleID, Flags, Params, VarResult, ExcepInfo, ArgErr);
  except
    on E: Exception do begin
      AddLog('*** Obj.Invoke *'+E.Message);
    end;
  end;
end;
//------------------------------------------------------------------------------
// Настройки
//------------------------------------------------------------------------------
function TAddInObject.LoadProperties: Boolean;
var
   iRes : Integer;
   varRead : OleVariant;
begin
  VarClear(varRead);
  varRead := 0;

  iRes := pProfile.Read('flDelNPP:0', varRead, nil);
  if (iRes <> S_OK) then begin
    LoadProperties := False;
    AddLog('>->'+inttostr(VarType(varRead)));
    Exit;
  end;
  flDelNPP := varRead;

  iRes := pProfile.Read('flDebugFile:0', varRead, nil);
  if (iRes <> S_OK) then begin
    LoadProperties := False;
    AddLog('>->'+inttostr(VarType(varRead)));
    Exit;
  end;
//  AddLog('>+>'+inttostr(VarType(varRead)));
  flDebugFile := varRead;

  LoadProperties := True;
end;
//------------------------------------------------------------------------------
procedure TAddInObject.SaveProperties;
var
   varSave : OleVariant;
begin

   varSave := flDelNPP;
   pProfile. Write('flDelNPP:0', varSave);
   pProfile. Write('flDebugFile:0', varSave);
end;
//------------------------------------------------------------------------------
function TAddInObject.GetNParam(var pArray : PSafeArray; lIndex: Integer ): OleVariant;
var varGet : OleVariant;
begin
   SafeArrayGetElement(pArray,lIndex,varGet);
   GetNParam := varGet;
end;
//------------------------------------------------------------------------------
procedure TAddInObject.PutNParam(var pArray: PSafeArray; lIndex: Integer; var varPut: OleVariant);
begin
  SafeArrayPutElement(pArray,lIndex,varPut);
end;
//------------------------------------------------------------------------------
{ IInitDone interface }
//------------------------------------------------------------------------------
function TAddInObject.Init(pConnection: IDispatch): HResult; stdcall;
var iRes : Integer;
begin
  AddIn:=Self;
  App:='7';
  frmMain:=TfrmMain.Create(Application);
  Obj.GetPropVal(PropertyVal, 'IsOpen').Val:=0;
//  Obj.GetPropVal(PropertyVal, 'Version').Val:=vGetInfo();

  pConnect := pConnection;

  pErrorLog := nil;
  pConnection.QueryInterface(IID_IErrorLog,pErrorLog);

  pEvent := nil;
  pConnection.QueryInterface(IID_IAsyncEvent,pEvent);
  pEvent.SetEventBufferDepth(10);

  pProfile := nil;
  iRes := pConnection.QueryInterface(IID_IPropertyProfile, pProfile);
  if (iRes = S_OK) then begin
    pProfile.RegisterProfileAs('Telnet extension');
    if (LoadProperties() <> True) then begin
      //Init := E_FAIL;
      //Exit;
    end;
  end;

  pStatusLine := nil;
  pConnection.QueryInterface(IID_IStatusLine,pStatusLine);

  pExtWndsSupport := nil;   // ++
  pConnection.QueryInterface(IID_IExtWndsSupport, pExtWndsSupport); // ++

  tmrProc := TTimer.Create(NIL);
  tmrProc.Interval:=100;
  tmrProc.Enabled := false;
  tmrProc.OnTimer := OnTmrProc; //++

  tmrEC := TTimer.Create(NIL);
  tmrEC.Interval:=1000;
  tmrEC.Enabled := False;
  tmrEC.OnTimer := OnTmrEC;

  tmrLive := TTimer.Create(NIL);
  tmrLive.Interval:=500;
  tmrLive.Enabled := False;
  tmrLive.OnTimer := OnTmrLive; //++

  AppTimeOut:=200;

  Init := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.Done: HResult; stdcall;
begin
  SaveProperties();

  F1C:=unassigned; // ++

  pConnect := unassigned;
  pErrorLog := nil;
  pEvent := nil;
  pProfile := nil;
  pStatusLine := nil;
  pExtWndsSupport := nil;   // ++

  if Assigned(tmrProc) then tmrProc.Destroy();
  if Assigned(tmrLive) then tmrLive.Destroy();
  Done := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.GetInfo(var pInfo: PSafeArray{(OleVariant)}): HResult; stdcall;
var  varInfo : OleVariant;
begin
     varInfo := '1000';
     PutNParam(pInfo,0,varInfo);
     GetInfo := S_OK;
end;
//------------------------------------------------------------------------------
{ ISpecifyPropertyPages interface }
//------------------------------------------------------------------------------
function TAddInObject.GetPages(out Pages: TCAGUID) : HResult; stdcall;
begin
     Pages.cElems := 1;
     Pages.pElems := CoTaskMemAlloc(SizeOf(TGUID));
     (Pages.pElems)[0] := Class_AddInPropPage;
     GetPages := S_OK;
end;
//------------------------------------------------------------------------------
{ ILanguageExtender interface }
//------------------------------------------------------------------------------
function TAddInObject.RegisterExtensionAs(var bstrExtensionName: WideString): HResult; stdcall;
begin
     bstrExtensionName := 'TlnExt5';
     RegisterExtensionAs := S_OK;
end;
//------------------------------------------------------------------------------
// Свойства
//------------------------------------------------------------------------------
function TAddInObject.GetNProps(var plProps: Integer): HResult; stdcall;
begin
  plProps := Obj.fIDs.Count;
  GetNProps := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.FindProp(const bstrPropName: WideString; var plPropNum: Integer): HResult; stdcall;
var
  i:word;
  lP:TPropertyLib;
begin
  plPropNum := -1;

  if Obj.fIDs.Count>0 then begin
    for i := 0 to Obj.fIDs.Count-1 do begin
      lP:=TPropertyLib(Obj.fIDs.Items[i]);
      if (bstrPropName=lP.Name1)or(bstrPropName=lP.Name2) then plPropNum:=i;
    end;
  end;

  if (plPropNum = -1) then begin
    FindProp := S_FALSE;
    Exit;
  end;
  FindProp := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.GetPropName(lPropNum, lPropAlias: Integer; var pbstrPropName: WideString): HResult; stdcall;
var
  lP:TPropertyLib;
begin
  pbstrPropName := '';

  if lPropNum<Obj.fIDs.Count then begin
    lP:=Obj.fIDs.Items[lPropNum];
    case lPropAlias of
      0: pbstrPropName := lP.Name1;
      1: pbstrPropName := lP.Name2;
    else
      GetPropName := S_FALSE;
      Exit;
    end;
  end;
  GetPropName := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.GetPropVal(lPropNum: Integer; var pvarPropVal: OleVariant): HResult; stdcall;
var
  lP:TPropertyLib;
  lF:TFunc;

  sParams:PSafeArray;
  v, lParams, ARet:OLEVariant;
begin
  try
    VarClear(pvarPropVal);


    if lPropNum<Obj.fIDs.Count then begin
      lP:=Obj.fIDs.Items[lPropNum];

      TMethod(lF).Code:=MethodAddress('propGet_'+lP.Name1);
      TMethod(lF).Data:=Self;
      if Assigned(TMethod(lF).Code) then begin
        sParams := PSafeArray(TVarData(lParams).VArray);
        lF(sParams, ARet);
        pvarPropVal:=ARet;
      end else begin
        pvarPropVal:=Obj.GetPropVal(PropertyVal, lP.Name1).Val;
      end;
      GetPropVal := S_OK;
      exit;
    end;
  except

  end;
  GetPropVal := S_FALSE;
end;
//------------------------------------------------------------------------------
function TAddInObject.SetPropVal(lPropNum: Integer; var varPropVal: OleVariant): HResult; stdcall;
var
  lP:TPropertyLib;
  lF:TFunc;

  sParams:PSafeArray;
  v, lParams, ARet:OLEVariant;
begin
  try
    if lPropNum<Obj.fIDs.Count then begin
      lP:=Obj.fIDs.Items[lPropNum];

      TMethod(lF).Code:=MethodAddress('propSet_'+lP.Name1);
      TMethod(lF).Data:=Self;
      if Assigned(TMethod(lF).Code) then begin
        sParams := PSafeArray(TVarData(lParams).VArray);
        lF(sParams, ARet);
        varPropVal:=ARet;
      end else begin
        Obj.GetPropVal(PropertyVal, lP.Name1).Val:=varPropVal;
        SetPropVal := S_OK;
        exit;
      end;
    end;
  except

  end;
  SetPropVal := S_FALSE;
end;
//------------------------------------------------------------------------------
function TAddInObject.IsPropReadable(lPropNum: Integer; var pboolPropRead: Integer): HResult; stdcall;
var
  lP:TPropertyLib;
begin
  if lPropNum<Obj.fIDs.Count then begin
    lP:=Obj.fIDs.Items[lPropNum];
    if lP.isReadable then pboolPropRead:=1 else pboolPropRead:=0;
    IsPropReadable := S_OK;
    exit;
  end;
  IsPropReadable := S_FALSE;
end;
//------------------------------------------------------------------------------
function TAddInObject.IsPropWritable(lPropNum: Integer; var pboolPropWrite: Integer): HResult; stdcall;
var
  lP:TPropertyLib;
begin
  if lPropNum<Obj.fIDs.Count then begin
    lP:=Obj.fIDs.Items[lPropNum];
    if lP.isReadable then pboolPropWrite:=1 else pboolPropWrite:=0;
    IsPropWritable := S_OK;
    exit;
  end;
  IsPropWritable := S_FALSE;
end;
//------------------------------------------------------------------------------
// Методы
//------------------------------------------------------------------------------
function TAddInObject.GetNMethods(var plMethods: Integer): HResult; stdcall;
begin
  plMethods := Obj.fIDs.Count;
  GetNMethods := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.FindMethod(const bstrMethodName: WideString; var plMethodNum: Integer): HResult; stdcall;
var
  i:word;
  lM:TMethodLib;
begin
  plMethodNum := -1;

  if Obj.fIDs.Count>0 then begin
    for i := 0 to Obj.fIDs.Count-1 do begin
      lM:=TMethodLib(Obj.fIDs.Items[i]);
      if (bstrMethodName=lM.Name1)or(bstrMethodName=lM.Name2) then plMethodNum:=i;
    end;
  end;

  if (plMethodNum = -1) then begin
    FindMethod := S_FALSE;
    Exit;
  end;
  FindMethod := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.GetMethodName(lMethodNum, lMethodAlias: Integer; var pbstrMethodName: WideString): HResult; stdcall;
var
  lM:TMethodLib;
begin
  GetMethodName := S_FALSE;
  pbstrMethodName := '';

  if lMethodNum<Obj.fIDs.Count then begin
    GetMethodName := S_OK;
    lM:=Obj.fIDs.Items[lMethodNum];
    case lMethodAlias of
      0: pbstrMethodName := lM.Name1;
      1: pbstrMethodName := lM.Name2;
    else
      GetMethodName := S_FALSE;
    end;
  end;
end;
//------------------------------------------------------------------------------
function TAddInObject.GetNParams(lMethodNum: Integer; var plParams: Integer): HResult; stdcall;
var
  lM:TMethodLib;
begin
  plParams := 0;

  if lMethodNum<Obj.fIDs.Count then begin
    lM:=TMethodLib(Obj.fIDs.Items[lMethodNum]);
    plParams:=lM.ParamsCount;
  end;
  GetNParams := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.GetParamDefValue(lMethodNum, lParamNum: Integer; var pvarParamDefValue: OleVariant): HResult; stdcall;
begin
  { Ther is no default value for any parameter }
  VarClear(pvarParamDefValue);
  GetParamDefValue := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.HasRetVal(lMethodNum: Integer; var pboolRetValue: Integer): HResult; stdcall;
var
  i:word;
  lM:TMethodLib;
begin
  pboolRetValue := 0;

  if lMethodNum<Obj.fIDs.Count then begin
    lM:=Obj.fIDs.Items[lMethodNum];
    if lM.isFunction then pboolRetValue := 1;
  end;

  HasRetVal := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.CallAsProc(lMethodNum: Integer; var paParams: PSafeArray{(OleVariant)}): HResult; stdcall;
var
  lM:TMethodLib;
  lRet:OLEVAriant;
  lf:TFunc;
begin
  CallAsProc := S_FALSE;

  if lMethodNum<Obj.fIDs.Count then begin
    lM:=Obj.fIDs.Items[lMethodNum];
    TMethod(lf).Code:=MethodAddress('meth_'+lM.Name1);
    TMethod(lf).Data:=Self;
    if Assigned(lf) then begin
      try
        lf(paParams, lRet);
      except on E:Exception do begin
          AddLog('Ошибка: '+E.Message);
          exit;
        end;
      end;
      CallAsProc := S_OK;
    end;
  end;
end;
//------------------------------------------------------------------------------
function TAddInObject.CallAsFunc(lMethodNum: Integer; var pvarRetValue: OleVariant; var paParams: PSafeArray{(OleVariant)}): HResult; stdcall;
var
  lM:TMethodLib;
  lRet:OLEVAriant;
  lf:TFunc;
begin
  CallAsFunc := S_FALSE;

  if lMethodNum<Obj.fIDs.Count then begin
    lM:=Obj.fIDs.Items[lMethodNum];
    TMethod(lf).Code:=MethodAddress('meth_'+lM.Name1);
    TMethod(lf).Data:=Self;
    if Assigned(lf) then begin
      try
        lf(paParams, lRet);
        pvarRetValue:=lRet;

      except on E:Exception do begin
          AddLog('Ошибка: '+E.Message);
          exit;
        end;
      end;
      CallAsFunc := S_OK;
    end
  end;
end;
//------------------------------------------------------------------------------
//
//------------------------------------------------------------------------------
Function DelNPP(tStr:AnsiString):AnsiString;
var
  i:word;
begin
  Result:='';
  for i := 1 to Length(tStr) do begin
    if byte(tStr[i])=160 then continue;
    Result:=Result+tStr[i];
  end;
end;
//------------------------------------------------------------------------------
function TAddInObject.propGet_Version(paParams: PSafeArray; var ARet: OleVariant): HResult; stdcall;
begin
  ARet:=vGetInfo();
  Result:=S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.propGet_Log(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
begin
  ARet:=frmMain.memoLog.Lines.Text;
  Result:=S_OK;
end;
//------------------------------------------------------------------------------
function GetLogTop(ACount:integer):string;
var
  i,j:integer;
begin
  Result:='';
  try
    i:=AddIn.frmMain.memoLog.Lines.Count;
    if i<=0 then exit;
    j:=i-ACount;
    if j<0 then j:=0;

    while j<i do begin
      Result:=Result+AddIn.frmMain.memoLog.Lines[j]+#13#10;
      inc(j);
    end;
  except
    on E:Exception do begin
      Result:='Ошибка: '+E.Message;
      AddLog(Result);
    end;
  end;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_LogTop(paParams: PSafeArray; var ARet: OleVariant): HResult; stdcall;
begin
  ARet:=GetLogTop(GetNParam(paParams,0));
  Result:=S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_LogClear(paParams: PSafeArray; var ARet: OleVariant): HResult; stdcall;
begin
  frmMain.memoLog.Lines.Clear;
  Result:=S_OK;
end;
//------------------------------------------------------------------------------
procedure TAddInObject.fAddLog(tStr:String);
var
  ls:String;
  LogFile:Text;
begin
  if frmMain=nil then frmMain:=TfrmMain.Create(Application);
  
  frmMain.memoLog.Lines.Add(DateTimeToStr(Now)+': '+trim(tStr));

  if flDebugFile=1 then begin
    ls:=ExtractFilePath(ParamStr(0))+'TlnExt5'+IntToStr(SessionIndex)+'.log';
    AssignFile(LogFile, ls);
    If FileExists(ls) then Append(LogFile) else ReWrite(LogFile);
    WriteLn(LogFile, DateTimeToStr(Now)+#9+tStr);
    CloseFile(LogFile);
  end;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_Enable;
begin
  meth_Enable := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_Disable;
begin
  //frmMain.Destroy;
  meth_Disable := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_Quit(paParams: PSafeArray; var ARet: OleVariant): HResult; stdcall;
begin
  F1C:=unassigned;
  meth_Quit := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_UpdActive(paParams: PSafeArray; var ARet: OleVariant): HResult; stdcall;
begin
  fFileMap.WriteTicker();
  meth_UpdActive := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_Open(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
var
  i:word;
  ls:string;
  lerr:AnsiString;
  lf:string;
  lTime:TDateTime;
  lPack:tPack;

  lID:string;
begin
  try
    fFileMap:=tFileMap.Create;
    tmrProc.Enabled := true;
    fFileMap.TimeOut:=AppTimeOut;

    with AddIn do begin
      F1C:=GetNParam(paParams, 0);
      lID:=GetNParam(paParams, 1);
      AddLog('Тип параметра запуска '+inttostr(varType(F1C)));
      if varType(F1C)=9 then App:='8' else App:='7_'+VarToStr(F1C);
      frmMain.AddInObject:=AddIn;

      if lID='' then begin
        // Получение параметров запуска
        For i:=1 To ParamCount do begin
          ls:=ParamStr(i);
          if LeftStr(ls, 3)='/ID' then begin
            lID:=trim(MidStr(ls, 4, Length(ls)));
            break;
          end else lID:='0';
        end;
      end;

      // Подключение к файлу
      lf:='ManagerApp'+lID;
      AddLog('Открытие файла '+lf);
      if fFileMap.Open(lf)<>0 then begin
        AddLog('Открытие файла невозможно');
        Result := E_FAIL;
        Exit;
      end;
      AddLog('Открыт файл '+lf);
      SessionIndex:=strtoint(lID);
      //ls:=trim(PAnsiChar(lpBaseAddr+10));
      //if ls='' then hMain:=0 else hMain:=strtoint(ls);
    end;
  except
    on E:Exception do begin
      AddLog('Ошибка: '+E.Message);
    end;
  end;

  try
    if fFileMap.WaitFor('INIT', lPack, 15)<>0 then begin
      AddLog('Закончилось время ожидания получения команды инициализации.');
      Result := S_FALSE;
      exit;
    end;
    //fFileMap.Read(lPack);
    //AddLog(lPack.Cmd+', '+inttostr(Length(lPack.Data)));
    AddLog(lPack.Cmd+', '+lPack.Data);


    //sTime:=Now+AppTimeOut*1/24/60/60;
    fFileMap.Write('ANSWER', '250', inttohex(AddIn.frmMain.Handle, 8));
//    WriteFM(10, inttohex(AddIn.frmMain.Handle, 8));
//    WriteFM(19, inttohex(0, 8));
//    WriteFM( 0, 'ANSWER');
  except
    on E:Exception do begin
      lerr:='Ошибка: '+E.Message;
      AddLog(lerr);
      Result := S_FALSE;
      exit;
    end;
  end;
  try
    Obj.GetPropVal(PropertyVal, 'IsOpen').Val := 1;
    AddIn.tmrLive.Enabled:=true;
    AddLog('Enable ok');
  except
    on E:Exception do begin
      lerr:='Ошибка: '+E.Message;
      AddLog(lerr);
      Result := S_FALSE;
      exit;
    end;
  end;
  Result := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_Connect(paParams: PSafeArray; var ARet: OleVariant):HRESULT; stdcall;
var
  str:pwidechar;
begin
  AddLog('Connect..');
  try
    ARet:=ComObj.CreateOLEObject('AddIn.TlnExt5_Ret');
    ARet.Code:='200';
  except on E:Exception do begin
      AddLog('Ошибка: '+E.Message);
      ARet := '300 '+E.Message;
      exit;
    end;
  end;
  try
    if frmMain.Clt.Connected then begin
      frmMain.Clt.Disconnect;
      frmMain.Clt.InputBuffer.Clear;
    end;
    frmMain.Clt.Host:=GetNParam(paParams, 0);
    frmMain.Clt.Port:=GetNParam(paParams, 1);
    frmMain.Clt.Connect;
    frmMain.Clt.ReadLn(#13#10, 1000);
  except
    on E:Exception do begin
      AddLog('Ошибка: '+E.Message);
      ARet.Code := '350';
      ARet.Answer:=E.Message;
      ARet.Code := '350'+E.Message;
    end;
  end;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_Disconnect;
begin
  AddLog('Disconnect..');
  try
    ARet:=ComObj.CreateOLEObject('AddIn.TlnExt5_Ret');
    ARet.Code:='200';
  except on E:Exception do begin
      AddLog('Ошибка: '+E.Message);
      ARet := '300 '+E.Message;
      exit;
    end;
  end;
  try
    if frmMain.Clt.Connected then frmMain.Clt.Disconnect;
  except on E:Exception do begin
      AddLog('Ошибка: '+E.Message);
      ARet := '350 '+E.Message;
      exit;
    end;
  end;

  meth_Disconnect := S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_Send;
var
  ls:AnsiString;
  lRes: Integer;
  lResp:TStringList;
  i:integer;
  v:variant;
  lPVal:TPropertyVal;
begin
  AddLog('Send '+ls);
  meth_Send := S_OK;

  try
    ARet:=ComObj.CreateOLEObject('AddIn.TlnExt5_Ret');
    ARet.Code:='200';
  except on E:Exception do begin
      AddLog('Ошибка: '+E.Message);
      ARet := '300 '+E.Message;
      exit;
    end;
  end;
  try
    ls:=GetNParam(paParams, 0);
    lRes:=frmMain.Clt.SendCmd(ls);
    ARet.Code:=inttostr(lRes);

    case lRes of
      250..289,350..399: begin
        lResp:=TStringList.Create;
        frmMain.Clt.Capture(lResp);
        I:=lResp.Count-1;
        while I>=0 do begin
          if (lResp[I]='200 NOP')OR(lResp[I]=#13#10) then lResp.Delete(I);
          dec(I);
        end;
        ARet.Answer:=lResp.Text;
        AddLog('Answer '+IntToStr(lRes)+' '+LeftStr(lResp.Text, 20)+'...');
      end;
    else
      AddLog('Answer '+IntToStr(lRes));
    end;
  except
    on E: Exception do begin
      AddLog('Not send.'+E.Message);
      ARet.Code:='350';
      ARet.Answer:=E.Message;
    end
  end;
end;
//------------------------------------------------------------------------------
function TAddInObject.propGet_AppTimeOut(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
begin
  ARet:=AppTimeout;
  Result:=S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.propSet_AppTimeOut(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
begin
  AppTimeout:=ARet;
  Result:=S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.propGet_SocketTimeOut(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
begin
  ARet:=frmMain.Clt.ReadTimeout;
  Result:=S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.propSet_SocketTimeOut(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
begin
  frmMain.Clt.ReadTimeout:=ARet;
  Result:=S_OK;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_Result_EC;
begin

end;
//------------------------------------------------------------------------------
function TAddInObject.CmdProc7;
var
  lRes, lVal:AnsiString;
  v77:OLEVariant;
  lr:integer;
begin
  try
    if lCmd='ec' then begin
      try
        Result_EC:='';
        lVal:='';
        lRes:='250';
        pEvent._AddRef;
        pEvent.ExternalEvent('TLNExt5', 'Command', lParam);
      except
        on E: Exception do begin
          lVal:=E.Message;
          lRes:='300';
        end;
      end;
    end;
    if lCmd='eb' then begin
      v77:=pConnect.AppDispatch;
      IDispatch(v77)._AddRef;

      lVal:='';
      lRes:='250';
      try
        lr:=v77.ExecuteBatch(lParam);
        if lr=0 then begin
          lVal:='';
          lRes:='301';
        end;
      except
        on E: Exception do begin
          lVal:=E.Message;
          lRes:='300';
        end;
      end;
    end;
    if lCmd='ee' then begin
      v77:=pConnect.AppDispatch;
      IDispatch(v77)._AddRef;

      lVal:='';
      lRes:='250';
      try
        lVal:=v77.EvalExpr(lParam);
      except
        on E: Exception do begin
          lVal:=E.Message;
          lRes:='301';
        end;
      end;
    end;
  except
    on E: Exception do begin
      lRes:='301';
      lVal:=E.Message;
    end;
  end;

  Result:=lRes+#9+lVal;
end;
//------------------------------------------------------------------------------
function TAddInObject.CmdProc7_1;
var
  lRes, lVal:AnsiString;
  v77:OLEVariant;
  lr:integer;
begin
  try
    lRes:='250';
    if lCmd='ee' then begin
      v77:=pConnect.AppDispatch;
      IDispatch(v77)._AddRef;

      try
        lVal:=v77.vkEvalExpr(lParam);
      except
        on E: Exception do begin
          lVal:='301'+#9+E.Message;
        end;
      end;
    end;
    if lCmd='eb' then begin
      v77:=pConnect.AppDispatch;
      IDispatch(v77)._AddRef;

      try
        lVal:=v77.vkExecuteBatch(lParam);
      except
        on E: Exception do begin
          lVal:='301'+#9+E.Message;
        end;
      end;
    end;
    if lCmd='ec' then begin
      try
        Result_EC:='';
        lVal:='';
        lRes:='250';
        pEvent._AddRef;
        lVal:=v77.vkEvalExpr(lParam);
        pEvent.ExternalEvent('TLNExt5', 'Command', lParam);
      except
        on E: Exception do begin
          lVal:=E.Message;
          lRes:='300';
        end;
      end;
    end;
  except
    on E: Exception do begin
      lRes:='301';
      lVal:=E.Message;
    end;
  end;

  Result:=lRes+#9+lVal;
end;
//------------------------------------------------------------------------------
function TAddInObject.CmdProc8;
var
  lRes, lVal:AnsiString;
  i:word;
begin
  lRes:='';
  if lCmd='ee' then begin
    try

      //AddLog('Prop count: '+F1C.OlePropertyGet('Форма'));

      lVal:=F1C.EvalExpr(lParam);
    except
      on E: Exception do begin
        lVal:='301'+#9+E.Message;
      end;
    end;
  end;

  if lCmd='ec' then begin
    try
      lVal:=F1C.ExecCmd(lParam);
    except
      on E: Exception do begin
        lVal:='301'+#9+E.Message;
      end;
    end;
  end;

  if lCmd='eb' then begin
    try
      lVal:=F1C.ExecBatch(lParam);
    except
      on E: Exception do begin
        lVal:='301'+#9+E.Message;
      end;
    end;
  end;
//   if flDelNPP=0 then Result:=lRes+#9+DelNPP(lVal) else Result:=lRes+#9+lVal;
   if flDelNPP=0 then Result:=DelNPP(lVal) else Result:=lVal;  // ответ формируется на стороне 1С
end;
//------------------------------------------------------------------------------
procedure TAddInObject.OnTmrLive(Sender: TObject);
begin
  //PostMessage(hMain, WMU_LIVE, 0, SessionIndex);
end;
//------------------------------------------------------------------------------
procedure TAddInObject.OnTmrEC(Sender: TObject);
begin
  AddLog('wait...');
  if Result_EC='' then exit;
  tmrEC.Enabled:=false;
  fFileMap.Write('ANSWER', '250', Result_EC);
  //WriteFM( 10, '250'+#9+Result_EC);
  //WriteFM( 0, 'ANSWER');
  AddLog('resw:'+Result_EC);
end;
//------------------------------------------------------------------------------
procedure TAddInObject.OnTmrProc(Sender: TObject);
var
  ls, lCmd, lRes, lReply:AnsiString;
  lc: PChar;
  lCmdD:char;
  fl:word;
  lPack:TPack;
  i:integer;
begin
  //tmrProc.Enabled := False;
  //PostMessage(hMain, WMU_LIVE, 0, SessionIndex);
  //sTime:=Now+AppTimeOut*1/24/60/60;
  //AddLog('...');

  //ls:=trim(PAnsiChar(lpBaseAddr));
  //if ls='ANSWER' then exit;
  //ls:=PAnsiChar(lpBaseAddr+10);
  if fFileMap.Read(lPack )<>0 then begin
      AddLog('Ошибка чтения файла обмена.');
    // Отработать ошибку
    exit;
  end;
  if lPack.Cmd<>'QUERY' then exit; // Нового запроса еще не пришло
  tmrProc.Enabled := False;
  //lc:=lPack.;
  //ls:=AnsiString(lc);
  ls:=lPack.Data;

  AddLog('fm: '+lPack.Cmd+', '+inttostr(Length(lPack.Data))+', '+ ls);
  if ls='' then exit;

  lReply:='501';
  lRes:='';
  fl:=0;
  //lCmdD:=#9;
  try
    lCmdD:=' ';
    //ls:=LowerCase(ls)+lCmdD;
    ls:=ls+lCmdD;
    lCmd:=LowerCase(LeftStr(ls+lCmdD, Pos(lCmdD, ls)-1));
    ls:=MidStr(ls, Pos(lCmdD, ls)+1, Length(ls)-Pos(lCmdD, ls));
    // Общие команды
    if lCmd='log' then begin
      fl:=1;
      if trim(ls)='' then begin
        lReply:='250';
        lRes:=frmMain.memoLog.Lines.Text;
      end else begin
        lReply:='250';
        lRes:=GetLogTop(strtoint(trim(ls)));
      end;
    end;
    if lCmd='logclear' then begin
      fl:=1;
      frmMain.memoLog.Lines.Clear;
      lReply:='250';
    end;
    // Команды, индивидуальные для различных приложений
    if fl=0 then begin
      if LeftStr(App, 1)='8' then begin
        lRes:=CmdProc8(lCmd, ls);
      end else begin
        if App='7_0' then lRes:=CmdProc7(lCmd, ls); // Работа через EvalExpr, внешняя обработка
        if App='7_1' then lRes:=CmdProc7_1(lCmd, ls); // Вызов процедур глобального модуля
      end;
      if LeftStr(lRes, 4)='Wait' then begin
        exit;
      end;
      // Разобьем ответ
      i:=Pos(#9, lRes);
      lReply:=LeftStr(lRes+#9, i-1);
      lRes:=MidStr(lRes, i+1, Length(lRes)-i);
    end;
  except
    on E: Exception do begin
      lReply:='351';
      lRes:=E.Message;
    end;
  end;
  fFileMap.Write('ANSWER', lReply, lRes);
  //WriteFM( 10, lRes);
  //WriteFM( 0, 'ANSWER');
  AddLog('res:'+lReply+' '+lRes);
  tmrProc.Enabled := true;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_HTTPPost(paParams: PSafeArray; var ARet: OleVariant):HResult;
var
  sl:TStringList;
  lURL, lRes:string;
begin
  AddLog('HTTP Post ');
  meth_HTTPPost := S_OK;
  try
    ARet:=ComObj.CreateOLEObject('AddIn.TlnExt5_Ret');
    ARet.Code:='250';
  except on E:Exception do begin
      AddLog('Ошибка: '+E.Message);
      ARet := '300 '+E.Message;
      exit;
    end;
  end;
  try
    lURL:=GetNParam(paParams, 0);
    sl:=TStringList.Create;
    ARet.Answer:=frmMain.idHTTP1.Post( lURL, sl);
  except
    on E:Exception do begin
      AddLog('Ошибка: '+E.Message);
      ARet.Code := '350';
      ARet.Answer:=E.Message;
      exit;
    end;
  end;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_GetClipBoardFile(paParams: PSafeArray; var ARet: OleVariant):HResult;
var
  i, j, numFiles:integer;
  buffer: array [0..MAX_PATH] of Char;
  f: THandle;
  lRes:string;
begin
  meth_GetClipBoardFile := S_OK;
  ARet.Code:='350';

  lRes:='';
  for i:=0 to Clipboard.FormatCount-1 do begin
    if Clipboard.Formats[i]=CF_HDROP then begin
      Clipboard.Open;
        try
          f := Clipboard.GetAsHandle(CF_HDROP);
          if f <> 0 then begin
            numFiles := DragQueryFile(f, $FFFFFFFF, nil, 0);
            for j := 0 to numfiles - 1 do begin
              buffer[0] := #0;
              DragQueryFile(f, j, buffer, SizeOf(buffer));
              lRes:=lRes+buffer+#9;
              ARet.Code:='250';
            end;
          end;
      finally
        Clipboard.Close;
      end;
    end;
  end;
  ARet.Answer:=lRes;
end;
//------------------------------------------------------------------------------
// COM port
//------------------------------------------------------------------------------
function TAddInObject.meth_COM_Open(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
var
 DCB   : TDCB;
 ANumber:byte;
 ASpeed:LongInt;

 CommTimeouts : TCommTimeouts;
 ComErrors    : DWORD;
begin
  meth_COM_Open := S_OK;
  try
    ARet:=ComObj.CreateOLEObject('AddIn.TlnExt5_Ret');
    ARet.Code:='350';
  except on E:Exception do begin
      AddLog('Ошибка: '+E.Message);
      ARet := '300 '+E.Message;
      exit;
    end;
  end;
  try
    // 1. Открываем файл
    ANumber:=GetNParam(paParams, 0);
    ASpeed:=GetNParam(paParams, 1);
    COMPort := CreateFile(PChar('COM'+IntToStr(ANumber)),
                      GENERIC_READ + GENERIC_WRITE,
                      0, nil,
                      OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    // 2. Контроль ошибок
    if COMPort = INVALID_HANDLE_VALUE then begin
     // Обнаружена ошибка, порт открыть не удалось
     exit;
    end;
    // 3. Чтение текущих настроек порта
    if GetCommState(COMPort, DCB) then ;
    // 4. Настройки:
    // Скорость обмена
    DCB.BaudRate := ASpeed;
    // Число бит на символ
    DCB.ByteSize := 8; //[размер "байта" при обмене по COM порту - обычно 8 бит];
    // Стоп-биты
    DCB.StopBits := 1; //[константа, определяющая кол-во стопбитов];
    // Четность
    DCB.Parity   := 0; //[константа, определяющая режим контроля четности];
    DCB.Flags := 20625;
    // 5. Передача настроек
    if not SetCommState(COMPort, DCB) then {ошибка настройки порта};
    // 6. Настройка буферов порта (очередей ввода и вывода)
    if not SetupComm(COMPort, 16, 16) then {ошибка настройки буферов};
    // 7. Сброс буфферов и очередей
    if PurgeComm(COMPort, PURGE_TXABORT or PURGE_RXABORT or PURGE_TXCLEAR or PURGE_RXCLEAR) then ;
    // Если соединение есть, то перенастроим его
    if COMPort <> INVALID_HANDLE_VALUE then begin
      // Чтение текущих таймаутов
      GetCommTimeouts(COMPort, CommTimeouts);
      //  ... настройка параметров структуры CommTimeouts ...
      CommTimeouts.ReadIntervalTimeout:=5;
      CommTimeouts.ReadTotalTimeoutMultiplier:=5;
      CommTimeouts.ReadTotalTimeoutConstant:=5;
      CommTimeouts.WriteTotalTimeoutMultiplier:=5;
      CommTimeouts.WriteTotalTimeoutConstant:=5;
      // Установка таймаутов
      SetCommTimeouts(COMPort, CommTimeouts);
    end;
    ARet.Code:='200';
    ARet.Answer:='Открыт COM'+inttostr(ANumber);
  except on E:Exception do begin
      AddLog('Ошибка: '+E.Message);
      ARet := '300 '+E.Message;
      exit;
    end;
  end;

end;
//------------------------------------------------------------------------------
function TAddInObject.meth_COM_Close(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
begin
  meth_COM_Close := S_OK;
  try
    ARet:=ComObj.CreateOLEObject('AddIn.TlnExt5_Ret');
    ARet.Code:='350';
  except on E:Exception do begin
      AddLog('Ошибка: '+E.Message);
      ARet := '300 '+E.Message;
      exit;
    end;
  end;
  try
    CloseHandle(COMPort);
    ARet.Code:='200';
  except
  end;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_COM_Read(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
var
  Err:longbool;
  Buffer:array [0..50] of AnsiChar;
  n:DWord;
begin
  meth_COM_Read := S_OK;
  try
    ARet:=ComObj.CreateOLEObject('AddIn.TlnExt5_Ret');
    ARet.Code:='350';
  except on E:Exception do begin
      AddLog('Ошибка: '+E.Message);
      ARet := '300 '+E.Message;
      exit;
    end;
  end;
  try
      Err := ReadFile(COMPort, Buffer, 1, n, nil);
      ARet.Code:='200';
      ARet.Answer:=Copy(Buffer, 0, n);
  except
  end;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_COM_ReadLN(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
var
  Err:longbool;
  Buffer:array [0..50] of AnsiChar;
  sBuffer:string;
  a, n:DWord;
  lDT:TDateTime;
  lRes:String;
begin
  meth_COM_ReadLN := S_OK;
  try
    ARet:=ComObj.CreateOLEObject('AddIn.TlnExt5_Ret');
    ARet.Code:='350';
  except on E:Exception do begin
      AddLog('Ошибка: '+E.Message);
      ARet := '300 '+E.Message;
      exit;
    end;
  end;
  try
      lDT:=Now+5*1/24/60/60;
      lRes:='';
      while lDT>Now do begin
        n:=0;
        Err := ReadFile(COMPort, Buffer, 1, n, nil);
        if n=0 then continue;
        for a:=0 to n-1 do lRes:=lRes+Buffer[a];
        if Pos(#13#10, lRes)>0 then begin
          ARet.Code:='200';
          break;
        end;
      end;
      ARet.Answer:=trim(lRes);
  except
      ARet.Code:='399';
  end;
end;
//------------------------------------------------------------------------------
function TAddInObject.meth_COM_Write(paParams: PSafeArray; var ARet:OLEVariant): HResult; stdcall;
var
  Buffer:array [0..50] of AnsiChar;
  sBuffer:string;
  Err:longbool;
  n:DWord;
begin
  meth_COM_Write := S_OK;
  try
    ARet:=ComObj.CreateOLEObject('AddIn.TlnExt5_Ret');
    ARet.Code:='350';
  except on E:Exception do begin
      AddLog('Ошибка: '+E.Message);
      ARet := '300 '+E.Message;
      exit;
    end;
  end;
  try
      sBuffer:=GetNParam(paParams, 0);
      for n:=1 to Length(sBuffer) do Buffer[n-1]:=sBuffer[n];
      n:=0;
      Err := WriteFile(COMPort, Buffer, Length(sBuffer), n, nil);

      ARet.Code:='200';
      ARet.Answer:='Записано '+inttostr(n)+' байт';
  except
  end;
end;
//------------------------------------------------------------------------------

initialization
//------------------------------------------------------------------------------
  ComServer.SetServerName('AddIn');
  TComObjectFactory.Create(ComServer, TAddInObject, CLSID_AddInObject,
                        'TlnExt5', 'V7 AddIn 2.0', ciSingleInstance, tmBoth);

  TComObjectFactory.Create(ComServer, TAddInRet, CLSID_AddInRet,
                        'TlnExt5_Ret', 'V7 AddIn 2.0', ciSingleInstance, tmBoth);

  TComObjectFactory.Create(ComServer, TAddInTable, CLSID_AddInTable,
                        'TlnExt5_Table', 'V7 AddIn 2.0', ciSingleInstance, tmBoth);

  TComObjectFactory.Create(ComServer, TAddInJSON, CLSID_AddInJSON,
                        'TlnExt5_JSON', 'V7 AddIn 2.0', ciSingleInstance, tmBoth);
//------------------------------------------------------------------------------
end.
//------------------------------------------------------------------------------

