unit UMapFile;

interface
Uses Windows, SysUtils, Classes;

//------------------------------------------------------------------------------
type
tPack=record
  Cmd:String;
  Reply:String;
  Data:String;
end;

tfPack=record
  Ticker:array[0..3] of byte;
  Cmd:array[0..10] of char;
  Reply:string[3];
  //Len:String[8];
  Len:array[0..3] of byte;
  Data:array [0..65535] of char;
end;

TOnLog=procedure (AMsg:String)of object;
TOnData=procedure (AData:String)of object;
//------------------------------------------------------------------------------
tThrWait=class (TThread)
  procedure Execute;override;
end;
//------------------------------------------------------------------------------
tFileMap=class
  private
    fHandle:THandle;
    lpBaseAddr:PChar;
    //fThrWait:tThrWait;
    fList:TThreadList;
    procedure fLog(AMsg:string);
  public
    Ticker:dword;
    TimeOut:integer;  // in sec
    OnLog:TOnLog;
    OnData:TOnLog;
    function Open(AName:string):integer;
    function WriteTicker():integer;
    function Write(ACmd, AReply, AData:string):integer;
    function Read(var APack:tPack):integer;
    function Init(ATimeOut:integer):integer;
    function WaitFor(ACmd:string; var APack:tPack; ATimeOut:integer=0):integer;
    function CheckFor(ACmd:string; var APack:tPack):integer;
end;
//------------------------------------------------------------------------------
implementation
//------------------------------------------------------------------------------
uses UMain;
//------------------------------------------------------------------------------
procedure tThrWait.Execute;
begin

end;
//------------------------------------------------------------------------------
// --- File mapping ------------------------------------------------------------
//------------------------------------------------------------------------------
procedure tFileMap.fLog;
begin
  if Assigned(OnLog) then OnLog(AMsg);
end;
//------------------------------------------------------------------------------
function tFileMap.Open(AName:string):integer;
var
  //lDT:TDateTime;
  lTO:integer;
  lList:TList;
begin
  Result:=0;
  //fList:=TThreadList.Create;
  //lList:=fList.LockList;

  lTO:=TimeOut*1000;
  while fHandle=0 do begin
    fHandle := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, 65000, PChar(AName));
    if lTO<=0 then break;
    sleep(1);
    dec(lTO);
  end;
  if fHandle = 0 then
    fLog('Не могу создать FileMapping!')
  else
    lpBaseAddr := MapViewOfFile(fHandle, FILE_MAP_WRITE, 0, 0, 0);
  if (fHandle=0)or(lpBaseAddr = nil) then begin
    fLog('Не могу подключить FileMapping!');
    Result:=-1;
    exit;
  end;
  //fList.UnlockList;
end;
//------------------------------------------------------------------------------
function tFileMap.WriteTicker;
var
  lPack:^tfPack;
  lPointer:Pointer;
  i,c:dword;
  lList:TList;
begin
  Result:=0;
  try

    lPointer:=lpBaseAddr;
    lPack:=lPointer;
    lPack.Reply:='';

    inc(Ticker);

    lPack.Ticker[0]:=LoByte(LoWord(Ticker));
    lPack.Ticker[1]:=HiByte(LoWord(Ticker));
    lPack.Ticker[2]:=LoByte(HiWord(Ticker));
    lPack.Ticker[3]:=HiByte(HiWord(Ticker));

  except
    Result:=-1;
  end;
end;
//------------------------------------------------------------------------------
function tFileMap.Write;
var
  lPack:^tfPack;
  lPointer:Pointer;
  i,c:dword;
  lList:TList;
begin
  Result:=0;
  try
    //lList:=fList.LockList;

    lPointer:=lpBaseAddr;
    lPack:=lPointer;
    lPack.Reply:='';
    //lPack.Data:=PChar(AData+#0);

    lPack.Ticker[0]:=LoByte(LoWord(Ticker));
    lPack.Ticker[1]:=HiByte(LoWord(Ticker));
    lPack.Ticker[2]:=LoByte(HiWord(Ticker));
    lPack.Ticker[3]:=HiByte(HiWord(Ticker));

    c:=Length(AData);
    if c>0 then for i:=0 to c-1 do lPack.Data[i]:=AData[i+1];
    lPack.Len[0]:=LoByte(LoWord(c));
    lPack.Len[1]:=HiByte(LoWord(c));
    lPack.Len[2]:=LoByte(HiWord(c));
    lPack.Len[3]:=HiByte(HiWord(c));

    //lPack.Len:=IntToHex(c, 8);
    lPack.Reply:=AReply;
    for i:=0 to 10 do lPack.Cmd[i]:=ACmd[i+1];
  except
    Result:=-1;
  end;
  //fList.UnlockList;
end;
//------------------------------------------------------------------------------
function tFileMap.Read;
var
  lPack:^tfPack;
  i, c:word;
  lList:TList;
  ls:string;
begin
  Result:=-1;
  try
    //lList:=fList.LockList;
    lPack:=Pointer(lpBaseAddr);

    c:=lPack^.Len[0]+lPack^.Len[1]*256+lPack^.Len[2]*256*256+lPack^.Len[3]*256*256*256;
    ls:='';

    if c>0 then for i:=0 to c-1 do ls:=ls+lPack^.Data[i];
    APack.Cmd:=lPack^.Cmd;

    APack.Data:=ls;
    //if c>0 then for i:=0 to c-1 do APack.Data:=APack.Data+lPack^.Data[i];

    APack.Reply:=lPack^.Reply;

    Result:=0;
  except
  end;
  //fList.UnlockList;
end;
//------------------------------------------------------------------------------
function tFileMap.Init;
var
  //lDT:TDateTime;
  lPack:tPack;
begin
  Result:=-1;
  Self.Write('INIT', '', '');
  //Self.Write('INIT', inttohex(AHandle, 8));
  Result:=Self.WaitFor('ANSWER', lPack, ATimeOut);
  Self.Write('READY', '', '');
//  lDT:=Now+TimeOut/24/60/60;
//  repeat
//    if lDT>Now then break;
//    sleep(100);
//    Self.Read(lPack);
//  until lPack.Cmd='ANSWER';
end;
//------------------------------------------------------------------------------
function tFileMap.WaitFor;
var
  lDT:TDateTime;
  lTO:integer;
  lPack:^tfPack;
begin
  Result:=-1;
  if ATimeOut=0 then lTO:=TimeOut else lTO:=ATimeOut;
  lDT:=Now+lTO/24/60/60;
  repeat
    //if Terminated then break;
    if CheckFor(ACmd, APack)=0 then begin
      Result:=0;
      exit;
    end;
    sleep(1);
    //mainApplication.ProcessMessages;
  until Now>lDT;

{  Result:=-1;
  if ATimeOut=0 then lTO:=TimeOut else lTO:=ATimeOut;
  lTO:=lTO*1000;
  while lTO>0 do begin
    lPack:=Pointer(lpBaseAddr);
    if lPack^.Cmd=ACmd then begin
        Read(APack);
        Result:=0;
        exit;
    end;
    sleep(1);
    dec(lTO);
  end;}
end;
//------------------------------------------------------------------------------
function tFileMap.CheckFor;
begin
  Result:=-1;
  Self.Read(APack);
  if APack.Cmd=ACmd then begin
    Result:=0;
    exit;
  end;
end;
//------------------------------------------------------------------------------

end.

