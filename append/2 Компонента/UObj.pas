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
  JSON:TObj;  // формирование JSON

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
  if Length(ASender)>0 then begin // ищем имя свойства
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
  // Сервисные
  //Obj.AddMeth('Debug'           , 'Отладка'               , 1, false);
  Obj.AddProp('Version'         , 'Версия'                , true, false);
  Obj.AddProp('Log'             , 'Журнал'                , true, false);
  Obj.AddMeth('LogTop'          , 'ЖурналВерх'            , 1, true );
  Obj.AddMeth('LogClear'        , 'ЖурналОчистить'        , 0, false);
  // Файл маппинг - работа с серверным приложением
  Obj.AddMeth('Open'            , 'Открыть'               , 2, false);
  Obj.AddMeth('Quit'            , 'Выход'                 , 0, false);
  Obj.AddProp('IsOpen'          , 'Открыт'                , true, false);

  Obj.AddMeth('Result_EC'       , 'РезультатВК'           , 2, false);
  // Клиент телнет
  Obj.AddMeth('Connect'         , 'Подключить'            , 2, true );
  Obj.AddMeth('Disconnect'      , 'Отключить'             , 0, true );
  Obj.AddMeth('Send'            , 'Отправить'             , 1, true );
  Obj.AddProp('SocketTimeOut'   , 'ТаймаутСокета'         , true, true);
  Obj.AddProp('AppTimeOut'      , 'ТаймаутПриложения'     , true, true);

  // Клиент HTTP
  Obj.AddMeth('HTTPPost'        , ''                      , 1, true );
  // Буфер обмена
  Obj.AddMeth('GetClipBoardFile', ''                      , 1, true );

  // Работа с COM портом
  Obj.AddMeth('COM_Open'        , ''                      , 2, true );
  Obj.AddMeth('COM_Read'        , ''                      , 0, true );
  Obj.AddMeth('COM_ReadLN'      , ''                      , 0, true );
  Obj.AddMeth('COM_Write'       , ''                      , 1, true );
  Obj.AddMeth('COM_Close'       , ''                      , 0, true );

  //*** Ret ***
  Ret:=TObj.Create;
  Ret.Name:='AddInRet';
  Ret.AddProp('Code'  , 'Код'  , true, true);
  Ret.AddProp('Answer', 'Ответ', true, true);
  Ret.AddMeth('Table1C7', 'Таблица1С7', 2, true);
  Ret.AddMeth('Table', 'Таблица', 2, true);

  //*** Table ***
  Table:=TObj.Create;
  Table.Name:='AddInTable';
  Table.AddProp('RowCount'  , 'КоличествоСтрок'   , true, false);
  Table.AddProp('ColCount'  , 'КоличествоСтолбцов', true, false);
  Table.AddMeth('FromStr', 'ИзСтроки', 3, false);
  Table.AddMeth('Cells'  , 'Ячейки'  , 2, true );

  List:=TObj.Create;
  List.Name:='AddInList';
  List.AddProp('Count'  , 'Количество'   , true, false);
  List.AddMeth('Val'  , 'Зн'  , 1, true );

    //*** JSON - формирование JSON ***
  JSON:=TObj.Create;
  JSON.Name:='AddInJSON';
  JSON.AddProp('Text'  , 'Текст'   , true, false);
  JSON.AddMeth('Add'  , 'Добавить'  , 2, true );
  JSON.AddMeth('Destroy'  , 'Удалить'  , 2, true );


end.
