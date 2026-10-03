unit DebugForms;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, StdCtrls, ComCtrls,
  FonFiles, ExtCtrls;

//======================================================================================================================
type
//----------------------------------------------------------------------------------------------------------------------

  TDebugForm = class(TForm)

    MainPageControl: TPageControl;
    FonFileTabSheet: TTabSheet;
    FonFileMemo: TMemo;
    FonFilePanel: TPanel;
    FonSaveToFileButton: TButton;
    FonSaveDialog: TSaveDialog;

    procedure FormCreate(Sender: TObject);
    procedure FonSaveToFileButtonClick(Sender: TObject);

  public
    procedure DumpFonFile(FonFile: TFonFile; DumpChars: Boolean);
  end;

//======================================================================================================================
var
//----------------------------------------------------------------------------------------------------------------------

  DebugForm: TDebugForm;

//======================================================================================================================
implementation /////////////////////////////////////////////////////////////////////////////////////////////////////////
//----------------------------------------------------------------------------------------------------------------------

uses
  TypInfo,
  TextWindowProps,
  MainForms, FntFiles, RasterChars;

{$R *.dfm}

//======================================================================================================================
// TDebugForm
//----------------------------------------------------------------------------------------------------------------------

procedure TDebugForm.FormCreate(Sender: TObject);

begin
  TextWindowProps.TuneMemo(FonFileMemo);
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TDebugForm.DumpFonFile(FonFile: TFonFile; DumpChars: Boolean);

  //....................................................................................................................

  function ChrToStr(Value: Char): string;

  begin
    Result := '#' + IntToStr(Ord(Value));
    if (Value >= #32) and (Value <= #126) then
      Result := Result + ' = ''' + Value + '''';
  end;

  //....................................................................................................................

var
  I: Integer;
  TabSheet: TTabSheet;
  FntFileMemo: TMemo;
  FntFile: TFntFile;
  CharRichEdit: TRichEdit;
  Splitter: TSplitter;
  C: Integer;
  RasterChar: TRasterChar;
  X, Y: Integer;
  S: string;

begin
  FonFileMemo.Clear;

  FonFileMemo.Lines.Add('Module name:            "' + FonFile.ModuleName + '"');
  FonFileMemo.Lines.Add('Description:            "' + FonFile.Description + '"');
  FonFileMemo.Lines.Add('');
  FonFileMemo.Lines.Add('File version number:    ' +
    Format('%d.%d.%d.%d',
    [FonFile.FileVersionNumber.Major,
    FonFile.FileVersionNumber.Minor,
    FonFile.FileVersionNumber.Release,
    FonFile.FileVersionNumber.Build]));
  FonFileMemo.Lines.Add('Product version number: ' +
    Format('%d.%d.%d.%d',
    [FonFile.ProductVersionNumber.Major,
    FonFile.ProductVersionNumber.Minor,
    FonFile.ProductVersionNumber.Release,
    FonFile.ProductVersionNumber.Build]));
  FonFileMemo.Lines.Add('');
  FonFileMemo.Lines.Add('Company name:           "' + FonFile.CompanyName + '"');
  FonFileMemo.Lines.Add('File description:       "' + FonFile.FileDescription + '"');
  FonFileMemo.Lines.Add('File version:           "' + FonFile.FileVersion + '"');
  FonFileMemo.Lines.Add('Internal name:          "' + FonFile.InternalName + '"');
  FonFileMemo.Lines.Add('Legal copyright:        "' + FonFile.LegalCopyright + '"');
  FonFileMemo.Lines.Add('Original file name:     "' + FonFile.OriginalFileName + '"');
  FonFileMemo.Lines.Add('Product name:           "' + FonFile.ProductName + '"');
  FonFileMemo.Lines.Add('Product version:        "' + FonFile.ProductVersion + '"');
  FonFileMemo.Lines.Add('');
  FonFileMemo.Lines.Add('Language code:          ' + IntToStr(FonFile.LanguageCode));
  FonFileMemo.Lines.Add('Char set code:          ' + IntToStr(FonFile.CharSetCode));
  FonFileMemo.Lines.Add('');
  FonFileMemo.Lines.Add('Number of fonts:        ' + IntToStr(FonFile.Fonts.Count));

  for I := 1 to MainPageControl.PageCount-1 do
    MainPageControl.Pages[1].Free;

  for I := 0 to FonFile.Fonts.Count-1 do
  begin
    FntFile := TFntFile(FonFile.Fonts[I]);
    TabSheet := TTabSheet.Create(nil);
    TabSheet.PageControl := MainPageControl;
    TabSheet.Caption := FntFile.FaceName + ' ' + IntToStr(FntFile.Points) + ' pt';

    FntFileMemo := TMemo.Create(TabSheet);
    FntFileMemo.Parent := TabSheet;
    if DumpChars then
      FntFileMemo.Align := alTop
    else
      FntFileMemo.Align := alClient;
    FntFileMemo.Height := 200;
    TextWindowProps.TuneMemo(FntFileMemo);
    FntFileMemo.ReadOnly := True;
    FntFileMemo.WordWrap := False;
    FntFileMemo.ScrollBars := ssBoth;

    FntFileMemo.Lines.Add('Face name:    "' + FntFile.FaceName + '"');
    FntFileMemo.Lines.Add('Copyright:    "' + FntFile.Copyright + '"');
    FntFileMemo.Lines.Add('Points:       ' + IntToStr(FntFile.Points));
    FntFileMemo.Lines.Add('VertRes:      ' + IntToStr(FntFile.VertRes));
    FntFileMemo.Lines.Add('HorizRes:     ' + IntToStr(FntFile.HorizRes));
    FntFileMemo.Lines.Add('Ascent:       ' + IntToStr(FntFile.Ascent));
    FntFileMemo.Lines.Add('IntLeading:   ' + IntToStr(FntFile.IntLeading));
    FntFileMemo.Lines.Add('ExtLeading:   ' + IntToStr(FntFile.ExtLeading));
    FntFileMemo.Lines.Add('Italic:       '+ BoolToStr(FntFile.Italic, {UseBoolStrs}True));
    FntFileMemo.Lines.Add('Underline:    ' + BoolToStr(FntFile.Underline, {UseBoolStrs}True));
    FntFileMemo.Lines.Add('StrikeOut:    ' + BoolToStr(FntFile.StrikeOut, {UseBoolStrs}True));
    FntFileMemo.Lines.Add('Weight:       ' + IntToStr(FntFile.Weight));
    FntFileMemo.Lines.Add('CharSet:      ' + IntToStr(FntFile.CharSet));
    FntFileMemo.Lines.Add('PixWidth:     ' + IntToStr(FntFile.PixWidth));
    FntFileMemo.Lines.Add('FixedPitch:   ' + BoolToStr(FntFile.FixedPitch, {UseBoolStrs}True));
    FntFileMemo.Lines.Add('Family:       ' +
      Copy(TypInfo.GetEnumName(TypeInfo(TFontFamily), Ord(FntFile.Family)),
      Length('cFontFamily_') + 1, MaxInt));
    FntFileMemo.Lines.Add('Default char: ' + ChrToStr(FntFile.DefaultChar));
    FntFileMemo.Lines.Add('Break char:   ' + ChrToStr(FntFile.BreakChar));
    FntFileMemo.Lines.Add('');
    FntFileMemo.Lines.Add('First char:   ' + ChrToStr(FntFile.FirstChar));
    FntFileMemo.Lines.Add('Chars count:  ' + IntToStr(FntFile.RasterCharsCount));

    if DumpChars then
    begin
      Splitter := TSplitter.Create(TabSheet);
      Splitter.Parent := TabSheet;
      Splitter.Align := alTop;
      Splitter.ResizeStyle := rsUpdate;
      Splitter.Width := 2;

      CharRichEdit := TRichEdit.Create(TabSheet);
      CharRichEdit.Parent := TabSheet;
      CharRichEdit.Align := alClient;
      TextWindowProps.TuneRichEdit(CharRichEdit);
      CharRichEdit.ReadOnly := True;
      CharRichEdit.WordWrap := False;
      CharRichEdit.ScrollBars := ssBoth;
      CharRichEdit.PlainText := True;
      CharRichEdit.Lines.BeginUpdate;
      try
        for C := 0 to FntFile.RasterCharsCount-1 do
        begin
          RasterChar := FntFile.RasterChars[C];

          CharRichEdit.Lines.Add('');
          CharRichEdit.Lines.Add('======= ' + IntToStr(C) + ' =======');
          CharRichEdit.Lines.Add('');

          for Y := 0 to RasterChar.Height-1 do
          begin
            S := '';
            for X := 0 to RasterChar.Width-1 do
            begin
              if RasterChar.Pixels[X, Y] then
                S := S + '*'
              else
                S := S + #183{small centered dot};
            end;
            CharRichEdit.Lines.Add(S);
          end;
        end;
      finally
        CharRichEdit.Lines.EndUpdate;
      end;
    end;
  end;
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TDebugForm.FonSaveToFileButtonClick(Sender: TObject);

begin
  if not FonSaveDialog.Execute then Exit;

  MainForm.FonFile.SaveToFile(FonSaveDialog.FileName);
end;

//======================================================================================================================
end.


