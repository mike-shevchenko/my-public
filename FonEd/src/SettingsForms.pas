unit SettingsForms;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ColorGrd, StdCtrls, ExtCtrls, ComCtrls, ToolWin;

type
  TSettingsForm = class(TForm)
    GroupBox2: TGroupBox;
    ColorDialog: TColorDialog;
    ComboBox1: TComboBox;
    Label16: TLabel;
    Label4: TLabel;
    Memo13: TMemo;
    Memo2: TMemo;
    Label2: TLabel;
    Label3: TLabel;
    Memo1: TMemo;
    Memo14: TMemo;
    Memo15: TMemo;
    Memo9: TMemo;
    Label5: TLabel;
    Label9: TLabel;
    Memo3: TMemo;
    Memo16: TMemo;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Memo4: TMemo;
    Memo5: TMemo;
    Memo6: TMemo;
    Memo7: TMemo;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    procedure Edit1Click(Sender: TObject);
    procedure Memo1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SettingsForm: TSettingsForm;

implementation

{$R *.dfm}

procedure TSettingsForm.Edit1Click(Sender: TObject);
begin
  ColorDialog.Execute;
end;

procedure TSettingsForm.Memo1Click(Sender: TObject);
begin
  ColorDialog.Execute;
end;

end.

