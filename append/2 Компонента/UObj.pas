unit UObj;

interface

uses Classes, ActiveX;

type
//------------------------------------------------------------------------------
TFunc=Function(paParams: PSafeArray; var ARet:OLEVariant): HRESULT of object; stdcall;
//------------------------------------------------------------------------------
TIDLib=class
  tID:integer;
  Name1,Name2:string;
end;
//------------------------------------------------------------------------------
TMethodLib=class(TIDLib)
  ParamsCount:word;
  isFunction:boolean;
end;
//------------------------------------------------------------------------------
TPropertyLib=class(TIDLib)
  isReadable:boolean;
  isWritable:boolean;
end;
//------------------------------------------------------------------------------
TPropertyVal=class
  Name:string;
  Val:OLEVariant;
end;
//------------------------------------------------------------------------------
TPropertyArray=array of TPropertyVal;
//PPropertyArray=^TPropertyArray;
//------------------------------------------------------------------------------
TObj=class
  Name:string;
  fIDs:TList;
  Constructor Create;
  Destructor Destroy;
  procedure AddMeth(ANameEng,ANameRus:string; AParamsCount:word; AisFunction:boolean);
  procedure AddProp(ANameEng,ANameRus:string; AisReadable:boolean; AisWritable:boolean);
  function GetProp(AName:string):TPropertyLib;
  function GetPropVal(var ASender:TPropertyArray; AName:string):TPropertyVal;
end;
//------------------------------------------------------------------------------
var
  Obj:TObj;
  Ret:TObj;
  Table:TObj;
  List:TObj;
  JSON:TObj;  // ������������ JSON

implementation

uses AddInObj;
//------------------------------------------------------------------------------
Constructor TObj.Create;
begin
  inherited Create;
  fIDs:=TList.Create;
end;
//------------------------------------------------------------------------------
Destructor TObj.Destroy;
begin
  fIDs.Destroy;
  inherited Destroy;
end;
//------------------------------------------------------------------------------
procedure TObj.AddProp(ANameEng: string; ANameRus: string; AisReadable: Boolean; AisWritable: Boolean);
var
  lP:TPropertyLib;
begin
  lP:=TPropertyLib.Create;
  lP.tID:=0;
  lP.Name1:=ANameEng;
  lP.Name2:=ANameRus;
  lP.isReadable:=AisReadable;
  lP.isWritable:=AisWritable;

  fIDs.Add(lP);
end;
//------------------------------------------------------------------------------
procedure TObj.AddMeth(ANameEng: string; ANameRus: string; AParamsCount: Word; AisFunction: Boolean);
var
  lM:TMethodLib;
begin
  lM:=TMethodLib.Create;
  lM.tID:=1;
  lM.Name1:=ANameEng;
  lM.Name2:=ANameRus;
  lM.ParamsCount:=AParamsCount;
  lM.isFunction:=AisFunction;
  fIDs.Add(lM);
end;
//------------------------------------------------------------------------------
function TObj.GetProp(AName: string):TPropertyLib;
var
  i:word;
  lP:TPropertyLib;
begin
  Result:=nil;
  if fIDs.Count>0 then begin
    for i := 0 to fIDs.Count-1 do begin
      lP:=TPropertyLib(fIDs.Items[i]);
      if (lP.Name1=AName)or(lP.Name2=AName) then begin
        Result:=lP;
        exit;
      end;
    end;
  end;
end;
//------------------------------------------------------------------------------
function TObj.GetPropVal(var ASender: TPropertyArray; AName: string):TPropertyVal;
var
  i:integer;

  lP:TPropertyVal;
begin
  if Length(ASender)>0 then begin // ���� ��� ��������
    for i := 0 to Length(ASender)-1 do begin
      if ASender[i].Name=AName then begin
        Result:=ASender[i];
        exit;
      end;
    end;
  end;
  i:=Length(ASender);
  SetLength(ASender, i+1);
  ASender[i]:=TPropertyVal.Create;
  ASender[i].Name:=AName;
  Result:=ASender[i];
end;
//------------------------------------------------------------------------------
begin
  //*** Obj ***
  Obj:=TObj.Create;
  Obj.Name:='AddInObj';
  // ���������
  //Obj.AddMeth('Debug'           , '�������'               , 1, false);
  Obj.AddProp('Version'         , '������'                , true, false);
  Obj.AddProp('Log'             , '������'                , true, false);
  Obj.AddMeth('LogTop'          , '����������'            , 1, true );
  Obj.AddMeth('LogClear'        , '��������������'        , 0, false);
  // ���� ������� - ������ � ��������� �����������
  Obj.AddMeth('Open'            , '�������'               , 2, false);
  Obj.AddMeth('Quit'            , '�����'                 , 0, false);
  Obj.AddProp('IsOpen'          , '������'                , true, false);

  Obj.AddMeth('Result_EC'       , '�����������'           , 2, false);
  // ������ ������
  Obj.AddMeth('Connect'         , '����������'            , 2, true );
  Obj.AddMeth('Disconnect'      , '���������'             , 0, true );
  Obj.AddMeth('Send'            , '���������'             , 1, true );
  Obj.AddProp('SocketTimeOut'   , '�������������'         , true, true);
  Obj.AddProp('AppTimeOut'      , '�����������������'     , true, true);

  // ������ HTTP
  Obj.AddMeth('HTTPPost'        , ''                      , 1, true );
  // ����� ������
  Obj.AddMeth('GetClipBoardFile', ''                      , 1, true );

  // ������ � COM ������
  Obj.AddMeth('COM_Open'        , ''                      , 2, true );
  Obj.AddMeth('COM_Read'        , ''                      , 0, true );
  Obj.AddMeth('COM_ReadLN'      , ''                      , 0, true );
  Obj.AddMeth('COM_Write'       , ''                      , 1, true );
  Obj.AddMeth('COM_Close'       , ''                      , 0, true );

  //*** Ret ***
  Ret:=TObj.Create;
  Ret.Name:='AddInRet';
  Ret.AddProp('Code'  , '���'  , true, true);
  Ret.AddProp('Answer', '�����', true, true);
  Ret.AddMeth('Table1C7', '�������1�7', 2, true);
  Ret.AddMeth('Table', '�������', 2, true);

  //*** Table ***
  Table:=TObj.Create;
  Table.Name:='AddInTable';
  Table.AddProp('RowCount'  , '���������������'   , true, false);
  Table.AddProp('ColCount'  , '������������������', true, false);
  Table.AddMeth('FromStr', '��������', 3, false);
  Table.AddMeth('Cells'  , '������'  , 2, true );

  List:=TObj.Create;
  List.Name:='AddInList';
  List.AddProp('Count'  , '����������'   , true, false);
  List.AddMeth('Val'  , '��'  , 1, true );

    //*** JSON - ������������ JSON ***
  JSON:=TObj.Create;
  JSON.Name:='AddInJSON';
  JSON.AddProp('Text'  , '�����'   , true, false);
  JSON.AddMeth('Add'  , '��������'  , 2, true );
  JSON.AddMeth('Destroy'  , '�������'  , 2, true );


end.
