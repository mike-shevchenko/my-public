program XMLParserTest;

uses
  QForms,
  Main in 'Main.pas' {MainForm},
  XMLParsers in '..\..\XMLParsers.pas',
  XMLWriters in '..\..\XMLWriters.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

