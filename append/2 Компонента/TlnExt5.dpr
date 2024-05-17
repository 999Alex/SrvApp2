library TlnExt5;

uses
  ComServ,
  AddInLib in 'AddInLib.pas',
  AddInObj in 'AddInObj.pas',
  PropPage in 'PropPage.pas' {AddInPropPage: TPropertyPage},
  UMain in 'UMain.pas' {frmMain} {/  UTlnExt_Types in 'UTlnExt_Types.pas' {Ret: CoClass},
  UMapFile in 'UMapFile.pas',
  UObj in 'UObj.pas';

{$E dll}

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer;

{$R *.RES}

begin

end.
