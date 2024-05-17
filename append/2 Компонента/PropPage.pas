unit PropPage;

interface

uses SysUtils, Windows, Messages, Classes, Graphics, Controls, StdCtrls,
  ExtCtrls, Forms, ComServ, ComObj, StdVcl, AxCtrls, AddInLib, Buttons;

type
  TAddInPropPage = class(TPropertyPage)
    IsOpen: TCheckBox;
    Slogan: TStaticText;
    flDelNPP: TCheckBox;
    Button1: TButton;
    Panel1: TPanel;
    memoLog: TMemo;
    SpeedButton1: TSpeedButton;
    flDebugFile: TCheckBox;
    procedure PropertyPageShow(Sender: TObject);
    procedure flDelNPPClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure flDebugFileClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure UpdatePropertyPage; override;
    procedure UpdateObject; override;
  end;

const
  Class_AddInPropPage: TGUID = '{ED3045F0-25AE-11D1-A4CB-004095E1DAEA}';

implementation

{$R *.DFM}

uses AddInObj, UObj;

//------------------------------------------------------------------------------
procedure TAddInPropPage.UpdatePropertyPage;
var
  iCheck : Integer;
//     pLink : IPropertyLink;
begin
//  iCheck:=Obj.GetProp('IsOpen').Val;
//  if (iCheck <> 0) then IsOpen.Checked := True else IsOpen.Checked := False;

  { Update your controls from OleObject }
//  pLink := IUnknown(OleObject) as IPropertyLink;
//  if (pLink <> nil) then
//     begin
//       iCheck:=Obj.GetProp('IsOpen').Val;
       //pLink.get_Open(iCheck);
//       if (iCheck <> 0) then
//         IsOpen.Checked := True
//         else IsOpen.Checked := False;
//     end;
end;
//------------------------------------------------------------------------------
procedure TAddInPropPage.Button1Click(Sender: TObject);
begin
  if AddIn.frmMain.Visible then AddIn.frmMain.Hide else AddIn.frmMain.Show;
end;
//------------------------------------------------------------------------------
procedure TAddInPropPage.flDebugFileClick(Sender: TObject);
var
  pVar: OLEVariant;
begin
  if flDebugFile.Checked then Addin.flDebugFile:=1 else Addin.flDebugFile:=0;
  pVar:=flDebugFile.Checked;
  if flDebugFile.Checked then AddLog('DebugFile true. '+ExtractFilePath(ParamStr(0))+'TlnExt'+IntToStr(AddIn.SessionIndex)+'.log') else  AddLog('DebugFile false');
end;
//------------------------------------------------------------------------------
procedure TAddInPropPage.flDelNPPClick(Sender: TObject);
var
  pVar: OLEVariant;
begin
  if flDelNPP.Checked then Addin.flDelNpp:=0 else Addin.flDelNpp:=-1;
  pVar:=flDelNPP.Checked;
  if flDelNPP.Checked then AddLog('DelNPP true') else  AddLog('DelNPP false');
//  TAddInObject(AddIn).pProfile.Write('flDelNPP', pVar);
end;
//------------------------------------------------------------------------------
procedure TAddInPropPage.PropertyPageShow(Sender: TObject);
var
  lP:TPropertyLib;
begin
  Slogan.Caption:=' ver. '+ vGetInfo();
  flDelNPP.Checked:=AddIn.flDelNpp=0;
  flDebugFile.Checked:=AddIn.flDebugFile=1;
//  lP:=Obj.GetProp('IsOpen');
//  if lP.Val=1 then lP.Val.Checked:=true else lP.Val.Checked:=false;
  memoLog.Lines.Text:=AddIn.frmMain.memoLog.Lines.Text;
end;
//------------------------------------------------------------------------------
procedure TAddInPropPage.SpeedButton1Click(Sender: TObject);
begin
  memoLog.Lines.Text:=AddIn.frmMain.memoLog.Lines.Text;
end;
//------------------------------------------------------------------------------
procedure TAddInPropPage.UpdateObject;
var
//  pLink : IPropertyLink;
  lP:TPropertyLib;
begin
//  lP:=Obj.GetProp('IsOpen');
//  if (IsOpen.Checked = True) then lP.Val:=1 else lP.Val:=0;

//  { Update OleObject from your controls }
//  pLink := IUnknown(OleObject) as IPropertyLink;
//  if (pLink <> nil) then begin
//    lP:=Obj.GetProp('IsOpen');
//    if (IsOpen.Checked = True) then lP.Val:=1 else lP.Val:=0;
//   end;
end;
//------------------------------------------------------------------------------
initialization
  TActiveXPropertyPageFactory.Create(
    ComServer,
    TAddInPropPage,
    Class_AddInPropPage);
end.
