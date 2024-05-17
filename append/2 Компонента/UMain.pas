unit UMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, AppEvnts, IdIntercept, IdGlobal, IdAuthentication, IdHTTP;

  Const
  WMU_TRANSFER=WM_USER+1;
  WMU_QUIT=WM_USER+2;
  WMU_LIVE=WM_USER+3;

type
//  String1251=type AnsiString(1251);

  TfrmMain = class(TForm)
    memoLog: TMemo;
    Panel1: TPanel;
    Button1: TButton;
    Clt: TIdTCPClient;
    ApplicationEvents1: TApplicationEvents;
    IdHTTP1: TIdHTTP;
    procedure ApplicationEvents1Message(var Msg: tagMSG; var Handled: Boolean);
    procedure IdHTTP1Connected(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    AddInObject:TObject;
    procedure WMTransfer(var Message: TMessage); message WMU_TRANSFER;
    procedure WMQuit(var Message: TMessage); message WMU_QUIT;
    procedure WMLive(var Message: TMessage); message WMU_LIVE;
  end;

implementation

uses AddInObj;
{$R *.dfm}

//------------------------------------------------------------------------------
procedure TfrmMain.WMTransfer;
begin
  TAddInObject(AddInObject).tmrProc.Enabled:=true;
end;
//------------------------------------------------------------------------------
procedure TfrmMain.WMQuit;
//var
//  v77:OLEVariant;
//  ls:string;
//  lAddInObject:TAddInObject;
begin
  try
//    hMain:=0;
//    lAddInObject:=TAddInObject(AddInObject);
//    lAddInObject.pEvent._AddRef;
//    lAddInObject.pEvent.ExternalEvent('TLN_Ext', 'Close', '');
  except
  end;
end;
//------------------------------------------------------------------------------
procedure TfrmMain.ApplicationEvents1Message(var Msg: tagMSG;
  var Handled: Boolean);
begin
//  memo1.Lines.Add('***')
end;
//------------------------------------------------------------------------------
procedure TfrmMain.IdHTTP1Connected(Sender: TObject);
begin
//  idHTTP1.IOHandler.DefStringEncoding:=IndyTextEncoding(IdTextEncodingType.encUTF8);
end;
//------------------------------------------------------------------------------
procedure TfrmMain.WMLive;
begin
  try
    //LastML:=Now;
  except
  end;
end;
//------------------------------------------------------------------------------

end.
