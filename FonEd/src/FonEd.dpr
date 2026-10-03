program FonEd;

uses
  Forms,
  MainForms in 'MainForms.pas' {MainForm},
  FonFiles in 'FonFiles.pas',
  FntFiles in 'FntFiles.pas',
  DebugForms in 'DebugForms.pas' {DebugForm},
  RasterChars in 'RasterChars.pas',
  StuffForms in 'StuffForms.pas' {StuffForm},
  SettingsForms in 'SettingsForms.pas' {SettingsForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TDebugForm, DebugForm);
  Application.CreateForm(TStuffForm, StuffForm);
  Application.CreateForm(TSettingsForm, SettingsForm);
  MainForm.Init;
  Application.Run;
end.

