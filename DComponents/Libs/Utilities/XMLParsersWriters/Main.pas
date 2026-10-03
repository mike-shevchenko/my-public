unit Main;

interface

uses
  SysUtils, Types, Classes, Variants, QTypes, QGraphics, QControls, QForms, QDialogs, QStdCtrls, Windows,
  XMLParsers;


type
  TMainForm = class(TForm)
    DumpMemo: TMemo;
    StartParsingButton: TButton;
    StopParsingButton: TButton;
    WriteButton: TButton;
    procedure StartParsingButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure StopParsingButtonClick(Sender: TObject);
    procedure WriteButtonClick(Sender: TObject);

  private
    FParser: TXMLParser;
    FStream: TFileStream;
  end;


var
  MainForm: TMainForm;


implementation

{$R *.xfm}


  uses
    XMLWriters;



  procedure TMainForm.StartParsingButtonClick(Sender: TObject);
  begin
    FStream := TFileStream.Create ('X.xml', fmOpenRead);
    FParser.StartParsing(FStream);
    DumpMemo.Clear;
    DumpMemo.Text := FParser.Root.DumpToWideString;
    while FParser.Root.NextChild <> nil do
    begin
      DumpMemo.Text := DumpMemo.Text + #10 + FParser.Root.Child.DumpToWideString;
      if FParser.Root.Child.Name = 'R' then
      begin
        DumpMemo.Text := DumpMemo.Text + '###  a="' + FParser.Root.Child.Att['a'] + '"'#10;
        DumpMemo.Text := DumpMemo.Text + '###  b="' + FParser.Root.Child.Att['b'] + '"'#10;
        DumpMemo.Text := DumpMemo.Text + '###  c="' + FParser.Root.Child.Att['c'] + '"'#10;
        DumpMemo.Text := DumpMemo.Text + '###  d="' + FParser.Root.Child.Att['d'] + '"'#10;
      end;
    end;
  end;



  procedure TMainForm.StopParsingButtonClick(Sender: TObject);
  begin
    FParser.StopParsing;
    FreeAndNil (FStream);
  end;



  procedure TMainForm.FormCreate(Sender: TObject);
  begin
    FParser := TXMLParser.Create;
    FParser.RegisterAtt('R', 'a', '_a');
    FParser.RegisterAtt('R', 'b', '_b');
    FParser.RegisterAtt('R', 'c', '_c');
  end;



  procedure TMainForm.FormDestroy(Sender: TObject);
  begin
    FParser.Free;
    FStream.Free;
  end;



  procedure TMainForm.WriteButtonClick(Sender: TObject);
  var
    Writer: TXMLWriter;
    MS: TMemoryStream;
  begin
    MS := TMemoryStream.Create();
    try
      Writer := TXMLWriter.Create ( MS,  cXMLEncoding_UTF8,  {WriteBOM} False,  {LineBreak} #10,  {UseIndents} True,
                                   {Indent} 0,  {SpaceAtts} False,  {SpaceEqs} False );
      try
        Writer.WriteXMLDecl ( {Version} '1.0',  {Standalone} -1 );  
        Writer.WriteNewLine;
        Writer.WriteDocType ('TEST', 'SystemID', '-//pub');
        Writer.WriteNewLine;
        Writer.WriteComment (' Comment ');
        Writer.WriteNewLine;
        Writer.StartElement  ('Root');
        Writer.StartElement  ('E1');
        Writer.WriteAtt ('att1', 'v''al1'#2'X', {DoubleQuotes}False);
        Writer.WriteAtt ('att2', 'v&al"2');
        Writer.WriteAtt ('att3',  WideString(WideChar($A2)) + WideString(WideChar($20AC)));
        Writer.FinishElement ('E1');
        Writer.StartElement  ('E2');
        Writer.FinishElement ('E2');
        Writer.FinishElement ('Root');
      finally
        Writer.Free;
      end;

      MS.SaveToFile('Written.xml');

    finally
      MS.Free;
    end;
  end;



end.

