unit StuffForms;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, StdCtrls, ExtCtrls, ComCtrls, ToolWin, Menus;

type
  TStuffForm = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label10: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    FontDirOpersLabel: TLabel;
    FontDirPanel: TPanel;
    FontDirNewButton: TSpeedButton;
    FontDirLoadButton: TSpeedButton;
    FontDirSaveButton: TSpeedButton;
    SpeedButton1: TSpeedButton;
    DirectoryLabel: TLabel;
    FontAddNewButton: TSpeedButton;
    FontAddFromFileButton: TSpeedButton;
    SelFontPanel: TPanel;
    SelFontDeleteButton: TSpeedButton;
    SelFontExportButton: TSpeedButton;
    SelFontReadBMPButton: TSpeedButton;
    SelFontWriteBMPButton: TSpeedButton;
    CheckBox4: TCheckBox;
    GroupBox1: TGroupBox;
    Label12: TLabel;
    Label9: TLabel;
    Label11: TLabel;
    Edit10: TEdit;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton4: TToolButton;
    ToolButton3: TToolButton;
    ToolButton7: TToolButton;
    ToolButton2: TToolButton;
    Edit8: TEdit;
    ToolsMainMenu: TMainMenu;
    File2: TMenuItem;
    Atthebeginning1: TMenuItem;
    Attheend2: TMenuItem;
    Delete2: TMenuItem;
    Atthebeginning2: TMenuItem;
    Attheend1: TMenuItem;
    Scroll1: TMenuItem;
    Up2: TMenuItem;
    Down2: TMenuItem;
    Left2: TMenuItem;
    Right2: TMenuItem;
    Fillwith1: TMenuItem;
    Withexistingfont1: TMenuItem;
    Width1: TMenuItem;
    N6: TMenuItem;
    Decrease1: TMenuItem;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  StuffForm: TStuffForm;

implementation

{$R *.dfm}

end.

