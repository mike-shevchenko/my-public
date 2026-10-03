unit MainForms;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs,
  FonFiles, StdCtrls, Spin, ComCtrls, ExtCtrls, Menus, Buttons, ToolWin,
  XPMan;

//======================================================================================================================
type
//----------------------------------------------------------------------------------------------------------------------

  TMainForm = class(TForm)
    MainMenu: TMainMenu;
    File1: TMenuItem;
    New1: TMenuItem;
    Open1: TMenuItem;
    Save1: TMenuItem;
    Saveas1: TMenuItem;
    Exit1: TMenuItem;
    N1: TMenuItem;
    Font1: TMenuItem;
    Delete1: TMenuItem;
    Exporttofile1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    Addnew1: TMenuItem;
    Importfromfile1: TMenuItem;
    N2: TMenuItem;
    Savebitmap1: TMenuItem;
    Loadbitmap1: TMenuItem;
    N3: TMenuItem;
    Properties1: TMenuItem;
    N4: TMenuItem;
    XPManifest: TXPManifest;
    Undoallchanges1: TMenuItem;
    Edit2: TMenuItem;
    Delete3: TMenuItem;
    Scroll2: TMenuItem;
    Fill1: TMenuItem;
    Width2: TMenuItem;
    Increase1: TMenuItem;
    Decrease2: TMenuItem;
    Left1: TMenuItem;
    Right1: TMenuItem;
    Up1: TMenuItem;
    Down1: TMenuItem;
    Options1: TMenuItem;
    Charactergrid1: TMenuItem;
    Pixelgrid1: TMenuItem;
    Chargridcolor1: TMenuItem;
    Zoomin1: TMenuItem;
    Zoomout1: TMenuItem;
    N8: TMenuItem;
    TabControl1: TTabControl;
    TopPanel: TPanel;
    Panel2: TPanel;
    Label17: TLabel;
    Label18: TLabel;
    Panel4: TPanel;
    Label13: TLabel;
    Label14: TLabel;
    Label1: TLabel;
    CheckBox2: TCheckBox;
    CheckBox1: TCheckBox;
    CheckBox4: TCheckBox;
    Panel3: TPanel;
    Label20: TLabel;
    Label16: TLabel;
    Label19: TLabel;
    Edit8: TEdit;
    Edit12: TEdit;
    UpDown1: TUpDown;
    UpDown2: TUpDown;
    UpDown3: TUpDown;
    Edit9: TEdit;
    Button1: TButton;
    TopRightPanel: TPanel;
    BottomPanel: TPanel;
    ScrollBox2: TScrollBox;
    Image2: TImage;
    Splitter1: TSplitter;
    EditorPopupMenu: TPopupMenu;
    Cut1: TMenuItem;
    Copy1: TMenuItem;
    Paste1: TMenuItem;
    CLear1: TMenuItem;
    Scroll1: TMenuItem;
    Up2: TMenuItem;
    Down2: TMenuItem;
    Left2: TMenuItem;
    Right2: TMenuItem;
    Width1: TMenuItem;
    Increase2: TMenuItem;
    Decrease1: TMenuItem;
    Capture1: TMenuItem;
    N5: TMenuItem;
    StatusBar1: TStatusBar;
    N6: TMenuItem;
    Highlightcurrentchar1: TMenuItem;
    N9: TMenuItem;
    PageControl: TPageControl;
    TabSheet1: TTabSheet;
    ScrollBox1: TScrollBox;
    Image1: TImage;
    Splitter2: TSplitter;
    TabSheet2: TTabSheet;
    Splitter3: TSplitter;
    ScrollBox3: TScrollBox;
    Memo1: TMemo;
    Memo2: TMemo;
    TabSheet3: TTabSheet;
    ScrollBox4: TScrollBox;
    Image3: TImage;
    Splitter4: TSplitter;
    Moveforward1: TMenuItem;
    N7: TMenuItem;
    Forward1: TMenuItem;
    Backwards1: TMenuItem;

    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);

  private
    FFonFile: TFonFile;

  public
    procedure Init;

    property FonFile: TFonFile read FFonFile;
  end;

//======================================================================================================================
var
//----------------------------------------------------------------------------------------------------------------------

  MainForm: TMainForm;

//======================================================================================================================
implementation /////////////////////////////////////////////////////////////////////////////////////////////////////////
//----------------------------------------------------------------------------------------------------------------------

uses
  FntFiles, DebugForms;

{$R *.dfm}

{$DEFINE DebugEnabled}

//======================================================================================================================
// TMainForm
//----------------------------------------------------------------------------------------------------------------------

procedure TMainForm.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

var
  DumpChars: Boolean;

begin
  {$IFDEF DebugEnabled}
    if [ssCtrl, ssAlt, ssShift] <= Shift then
    begin
      DumpChars := Application.MessageBox('Dump character bitmaps (takes a while)?',
        PChar(Application.Title), MB_YESNO) = ID_YES;
      DebugForm.DumpFonFile(FFonFile, DumpChars);
      DebugForm.Show;
    end;
  {$ENDIF}
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TMainForm.FormCreate(Sender: TObject);

var
  SkippedVectorFonts: Integer;
  SkippedUnsupportedFonts: Integer;

begin
  if ParamCount = 1 then
  begin
    try
      FFonFile := TFonFile.CreateFromFile(ParamStr(1), SkippedVectorFonts, SkippedUnsupportedFonts);
    except
      on EWrongFileFormat do
      begin
        Application.MessageBox(
          PChar('The font file "' + ParamStr(1) + '" has wrong or unsupported format.'),
          PChar(Application.Title),
          MB_ICONERROR);
        Halt(1);
      end
      else
      begin
        Application.ShowException(ExceptObject as Exception);
        Halt(1);
      end;
    end;

    MainForm.Caption := MainForm.Caption + ' - ' + ParamStr(1);

    if SkippedVectorFonts <> 0 then
    begin
      Application.MessageBox(
        PChar(IntToStr(SkippedVectorFonts) + ' vector fonts were found and skipped.'),
        PChar(Application.Title),
        MB_ICONWARNING);
    end;

    if SkippedUnsupportedFonts <> 0 then
    begin
      Application.MessageBox(
        PChar(IntToStr(SkippedUnsupportedFonts) + ' unsupported fonts were found and skipped.'),
        PChar(Application.Title),
        MB_ICONWARNING);
    end;
  end;

  // TODO: Set recursively DoubleBuffered -- introduce a new Libs unit.
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TMainForm.Init;

begin
  DebugForm.DumpFonFile(FFonFile, {DumpChars}False);
  DebugForm.Show;
end;

//======================================================================================================================
end.

