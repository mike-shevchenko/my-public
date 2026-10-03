{$B-}
unit TestRE;

{
 Simple test of regular expression

 (c) 1999-2001 Andrey V. Sorokin
  St-Petersburg
  Russia
  anso@mail.ru, anso@usa.net
  http://anso.da.ru
  http://anso.virtualave.net

 Thanks to Jon Smith for very usefull features suggested

}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ComCtrls, ExtCtrls,
  RegExpr, FileViewer;

type
  TfmTestRE = class(TForm)
    btnClose: TBitBtn;
    grpRegExpr: TGroupBox;
    OpenDialog1: TOpenDialog;
    cbHelpLanguage: TComboBox;
    btnHelp: TSpeedButton;
    lblWWW: TLabel;
    Bevel1: TBevel;
    PageControl1: TPageControl;
    tabExpression: TTabSheet;
    tabSubstitute: TTabSheet;
    pnlSubstitutionComment: TPanel;
    lblSubstitutionComment: TLabel;
    tabReplace: TTabSheet;
    pnlReplaceComment: TPanel;
    lblReplaceComment: TLabel;
    tabSplit: TTabSheet;
    btnSplit: TBitBtn;
    memSplitResult: TMemo;
    pnlSplitComment: TPanel;
    lblSplitComment: TLabel;
    lblSplitResult: TLabel;
    pnlTopExamples: TPanel;
    lblExamples: TLabel;
    btnTemplatePhonePiter: TSpeedButton;
    btnTemplatePhone: TSpeedButton;
    btnTemplatePassport: TSpeedButton;
    btnTemplateMail: TSpeedButton;
    btnTemplateInteger: TSpeedButton;
    btnTemplateRealNumber: TSpeedButton;
    btnTemplateRomanNumber: TSpeedButton;
    btnTemplateURL: TSpeedButton;
    btnSaintPetersburg: TSpeedButton;
    btnBackRef: TSpeedButton;
    btnNonGreedy: TSpeedButton;
    pnlReplaceTemplate: TPanel;
    lblReplaceString: TLabel;
    edReplaceString: TMemo;
    Splitter1: TSplitter;
    pnlReplaceResult: TPanel;
    lblReplaceResult: TLabel;
    memReplaceResult: TMemo;
    btnReplace: TBitBtn;
    pnlSubstitutionTemplate: TPanel;
    lblSubstitutionTemplate: TLabel;
    memSubstitutionTemplate: TMemo;
    Splitter2: TSplitter;
    pnlRegExpr: TPanel;
    gbModifiers: TGroupBox;
    chkModifierI: TCheckBox;
    chkModifierR: TCheckBox;
    chkModifierS: TCheckBox;
    chkModifierG: TCheckBox;
    chkModifierM: TCheckBox;
    lblRegExpr: TLabel;
    lblRegExprUnbalancedBrackets: TLabel;
    edRegExpr: TMemo;
    edSubExprs: TLabel;
    cbSubExprs: TComboBox;
    btnViewPCode: TSpeedButton;
    Splitter3: TSplitter;
    pnlSubstitutionResult: TPanel;
    lblSubstitutionResult: TLabel;
    memSubstitutionResult: TMemo;
    pnlInputStrings: TPanel;
    lblInputString: TLabel;
    edInputString: TMemo;
    lblInputStringPos: TLabel;
    edInputStringPos: TEdit;
    btnTestString: TBitBtn;
    btnExecNext: TBitBtn;
    btnFindRegExprInFile: TBitBtn;
    cbSubStrs: TComboBox;
    lblTestResult: TLabel;
    chkModifierX: TCheckBox;
    chkUseSubstitution: TCheckBox;
    procedure btnViewPCodeClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnTestStringClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnTemplatePhonePiterClick(Sender: TObject);
    procedure btnTemplatePhoneClick(Sender: TObject);
    procedure btnTemplatePassportClick(Sender: TObject);
    procedure btnTemplateMailClick(Sender: TObject);
    procedure btnTemplateIntegerClick(Sender: TObject);
    procedure btnTemplateRealNumberClick(Sender: TObject);
    procedure btnTemplateURLClick(Sender: TObject);
    procedure btnFindRegExprInFileClick(Sender: TObject);
    procedure btnExecNextClick(Sender: TObject);
    procedure btnReplaceClick(Sender: TObject);
    procedure btnSplitClick(Sender: TObject);
    procedure chkModifierIClick(Sender: TObject);
    procedure btnSaintPetersburgClick(Sender: TObject);
    procedure btnTemplateRomanNumberClick(Sender: TObject);
    procedure chkModifierSClick(Sender: TObject);
    procedure chkModifierRClick(Sender: TObject);
    procedure btnBackRefClick(Sender: TObject);
    procedure chkModifierGClick(Sender: TObject);
    procedure edRegExprChange(Sender: TObject);
    procedure cbSubExprsClick(Sender: TObject);
    procedure edInputStringClick(Sender: TObject);
    procedure edInputStringKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure edInputStringMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure edInputStringMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure edRegExprClick(Sender: TObject);
    procedure lblRegExprUnbalancedBracketsDblClick(Sender: TObject);
    procedure edRegExprKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbSubStrsClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure cbHelpLanguageClick(Sender: TObject);
    procedure chkModifierMClick(Sender: TObject);
    procedure btnNonGreedyClick(Sender: TObject);
    procedure lblWWWClick(Sender: TObject);
    procedure chkModifierXClick(Sender: TObject);
   private
    r : TRegExpr;
    procedure Compile;
    procedure ExecIt (AFindNext : boolean);
    procedure InputStringPosIsChanged;
    procedure RegExprChanged (AShowErrorPos : boolean = false);
    procedure RegExprPosIsChanged;
    procedure SubexprSelected;
    procedure SubStringSelected;
    procedure HelpLanguageSelected;
    procedure GoToRegExprHomePage;
    procedure UpdateModifiers;
   public
    procedure HighlightREInFileViewer (AFileViewer : TfmFileViewer);
  end;

var
  fmTestRE: TfmTestRE;

implementation
{$R *.DFM}

uses
 ShellAPI, // ShellExecute
 PCode;

procedure TfmTestRE.FormCreate(Sender: TObject);
 var
  ExeFolder : string;
 begin
  Caption := Format ('TRegExpr %d.%d test programm',
   [TRegExpr.VersionMajor, TRegExpr.VersionMinor]);

  r := TRegExpr.Create;

  // select help file, first try existed non-English,
  // if no one fuond, then English.
  ExeFolder := ExtractFilePath (Application.ExeName);
  if FileExists (ExeFolder + 'RegExpRu.hlp')
   then cbHelpLanguage.ItemIndex := 0
  else if FileExists (ExeFolder + 'RegExpBG.hlp')
   then cbHelpLanguage.ItemIndex := 2
  else if FileExists (ExeFolder + 'RegExpG.hlp')
   then cbHelpLanguage.ItemIndex := 3
  else if FileExists (ExeFolder + 'RegExpF.hlp')
   then cbHelpLanguage.ItemIndex := 4
  else if FileExists (ExeFolder + 'RegExpS.hlp')
   then cbHelpLanguage.ItemIndex := 5
  else cbHelpLanguage.ItemIndex := 1;
  HelpLanguageSelected;

  UpdateModifiers;

  btnTemplateMail.Click; // Select test r.e. and update GUI elements

  InputStringPosIsChanged;
 end;

procedure TfmTestRE.FormDestroy(Sender: TObject);
 begin
  if Assigned (r)
   then r.Free;
 end;

procedure TfmTestRE.UpdateModifiers;
 begin
  // show effective values of modifiers
  chkModifierI.Checked := r.ModifierI;
  chkModifierR.Checked := r.ModifierR;
  chkModifierS.Checked := r.ModifierS;
  chkModifierG.Checked := r.ModifierG;
  chkModifierM.Checked := r.ModifierM;
  chkModifierX.Checked := r.ModifierX;
 end;

procedure TfmTestRE.btnViewPCodeClick(Sender: TObject);
 begin
  Compile;
  with TfmPseudoCodeViewer.Create (Application) do begin
    edSource.Text := r.Expression;
    Memo1.Lines.Text := r.Dump;
    ShowModal;
   end;
 end;

procedure TfmTestRE.btnCloseClick(Sender: TObject);
 begin
  Close;
 end;

procedure TfmTestRE.Compile;
 begin
  try
    // r.e. precompilation (then you assign Expression property,
    // TRegExpr automatically compiles the r.e.).
    // Note:
    //   if there are errors in r.e. TRegExpr will raise
    //   exception.

    r.Expression := edRegExpr.Text;

    except on E:Exception do begin // exception during r.e. compilation or execution
      if E is ERegExpr then
       if (E as ERegExpr).CompilerErrorPos > 0 then begin
         // compilation exception - show place of error
         edRegExpr.SetFocus;
         edRegExpr.SelStart := (E as ERegExpr).CompilerErrorPos - 1;
         edRegExpr.SelLength := 1;
        end;
      raise Exception.Create (E.Message); // continue exception processing
     end;
   end;
 end;

procedure TfmTestRE.ExecIt (AFindNext : boolean);
 var
  i : integer;
  res : boolean;
  s : string;
 begin
  try
    // Assign r.e. to Expression property - it'll be
    // automatically compiled. If any errors occure,
    // ERegExpr will be raised
    Compile;

    // r.e. execution (finding r.e. occurences in input string)
    //
    // There are some examples of r.e. execution technics:
    // 1) Simple case (one r.e., many input strings)
    //      r.Exec (AInputString);
    //  Note
    //   if you don't need r.e. precompilation and only want
    //   to check one input string with one r.e. then you may
    //   use global routine:
    //      ExecRegExpr (ARegularExpression, AInputString);
    // 2) Search next match
    //      if r.Exec (AInputString) then // search first occurence
    //       REPEAT
    //        // loop body
    //       UNTIL not r.ExecNext; // search next occurences
    // 3) Search from any position
    //      r.InputString := AInputString;
    //      r.ExecPos (APositionOffset);

    if AFindNext
     then res := r.ExecNext // search next occurence. raise
                            // exception if no Exec call preceded
     else res := r.Exec (edInputString.Text); // search from first position
    if res then begin // r.e. found
       // Show r.e. positions: 0 - whole r.e.,
       // 1 .. SubExprMatchCount - subexpressions.
       lblTestResult.Caption := 'Reg.expr found:';
       lblTestResult.Font.Color := clGreen;

       cbSubStrs.Items.Clear;
       for i := 0 to r.SubExprMatchCount do begin
          s := '$' + IntToStr (i);
          if r.MatchPos [i] > 0
           then s := s + ' [' + IntToStr (r.MatchPos [i]) + ' - '
             + IntToStr (r.MatchPos [i] + r.MatchLen [i] - 1) + ']: '
             + r.Match [i]
           else s := s + ' not found!';
          cbSubStrs.Items.AddObject (s, TObject (r.MatchPos [i]
           + (r.MatchLen [i] ShL 16)));
         end;
       cbSubStrs.Visible := True;
       cbSubStrs.ItemIndex := 0;
       SubStringSelected;

       // Perform substitution - example of fill in template
       memSubstitutionResult.Text :=
        r.Substitute (PChar (memSubstitutionTemplate.Text));
      end
     else begin // r.e. not found
       cbSubStrs.Visible := False;
       lblTestResult.Caption := 'Regexpr. not found in string.';
       lblTestResult.Font.Color := clPurple;
       memSubstitutionResult.Text := 'Substitution is not performed';
      end;
    except on E:Exception do begin // exception during r.e. compilation or execution
      cbSubStrs.Visible := False;
      lblTestResult.Caption := 'Error: "' + E.Message + '"';
      lblTestResult.Font.Color := clRed;
      memSubstitutionResult.Text := 'Substitution is not performed';
     end;
   end;
 end;

procedure TfmTestRE.btnTestStringClick(Sender: TObject);
 begin
  ExecIt (false);
 end;

procedure TfmTestRE.btnExecNextClick(Sender: TObject);
 begin
  ExecIt (true);
 end;

procedure TfmTestRE.btnTemplatePhonePiterClick(Sender: TObject);
 begin
  edRegExpr.Text :=
   '\d{3}-?\d\d-?\d\d';
  edInputString.Text :=
   'The phone of AlkorSoft (project PayCash) is 329-4469 (St-Petersburg)';
  memSubstitutionTemplate.Text :=
   'Great payment system! E-cash is real ! Phone $&, PayCash.';
  edReplaceString.Text := '$& (international +7 (812) $&)';
  chkUseSubstitution.Checked := True;
  r.ModifierStr := '-x';
  UpdateModifiers;
 end;

procedure TfmTestRE.btnTemplatePhoneClick(Sender: TObject);
 begin
  edRegExpr.Text :=
   '(\+\d *)?(\(\d+\) *)?(\d+(-\d*)*)';
  edInputString.Text :=
   'Long distance phone of AlkorSoft (PayCash) is +7(812) 329-44-69';
  memSubstitutionTemplate.Text :=
   'If you call outside of Saint-Petersburg (zone code $1, city code $2), use $& for calling.';
  edReplaceString.Text := '$3';
  chkUseSubstitution.Checked := True;
  r.ModifierStr := '-x';
  UpdateModifiers;
 end;

procedure TfmTestRE.btnTemplatePassportClick(Sender: TObject);
 begin
  edRegExpr.Text :=
   '([IVXCL]{3}-[‡-ﬂ][‡-ﬂ] *[Nπ]? *)?(\d{6})';
  edInputString.Text :=
   'The example of russian passport number: IVX-Ÿ¿ 123456';
  memSubstitutionTemplate.Text :=
   'Number: $&';
  edReplaceString.Text := 'Series:$1, Number:$2';
  chkUseSubstitution.Checked := True;
  r.ModifierStr := '-x';
  UpdateModifiers;
 end;

procedure TfmTestRE.btnTemplateMailClick(Sender: TObject);
 begin
  edRegExpr.Text :=
   '[_a-zA-Z\d\-\.]+@([_a-zA-Z\d\-]+(\.[_a-zA-Z\d\-]+)+)';
  edInputString.Text :=
   'My e-mails is anso@mail.ru and anso@usa.net';
  memSubstitutionTemplate.Text :=
   'Please, all suggestions and bugreports mail'
   + 'to $& (Andrey Sorokin).';
  edReplaceString.Text := '<NoSPAM!>@$1';
  chkUseSubstitution.Checked := True;
  r.ModifierStr := '-x';
  UpdateModifiers;
 end;


procedure TfmTestRE.btnTemplateIntegerClick(Sender: TObject);
 begin
  edRegExpr.Text :=
     '# Remove ''^'' if something may precede number,'#$d#$a
   + '# and ''$'' if something may follow'#$d#$a
   + '^(?# BOL marker)[+\-]?\d+$(?# EOL marker)';
  edInputString.Text :=
   'Here is the number 123. Something after number.';
  memSubstitutionTemplate.Text :=
   'The r.e. above expects only digits in the string,'#$d#$a
   + ' because simbols of start and end of string'#$d#$a
   + ' (''^'' and ''$'').'#$d#$a
   + 'So, you must remove all non digits symbols in'#$d#$a
   + 'input string or symbols ''^'' and ''$'' in r.e.';
  edReplaceString.Text := '<here was digit>';
  chkUseSubstitution.Checked := False;
  r.ModifierStr := 'x';
  UpdateModifiers;
 end;

procedure TfmTestRE.btnTemplateRealNumberClick(Sender: TObject);
 begin
  edRegExpr.Text :=
   '^[+\-]?\d+(\.\d+)?([eE][+\-]?\d+)?$';
  edInputString.Text :=
   'Remove this123.0e6and this';
  memSubstitutionTemplate.Text :=
   'The r.e. above checks the start and end of string'
   + ' (symbols ''^'' and ''$'' in r.e.).'#$d#$a
   + 'So, you must remove this symbols from r.e. or'
   + ' all symbols before and after real number in'
   + ' input string.';
  edReplaceString.Text := '<here was digit>';
  chkUseSubstitution.Checked := False;
  r.ModifierStr := '-x';
  UpdateModifiers;
 end;

procedure TfmTestRE.btnTemplateURLClick(Sender: TObject);
 begin
  edRegExpr.Text :=
     '(?i)                          # we need caseInsensitive mode'#$d#$a
   + '(FTP|HTTP)://                 # protocol'#$d#$a
   + '([_a-z\d\-]+(\.[_a-z\d\-]+)+) # TCP addr'#$d#$a
   + '((/[ _a-z\d\-\\\.]+)+)*       # unix path';
  edInputString.Text :=
   'Welcome to my homepage http://anso.da.ru.'#$d#$a'E-cash http://www.paycash.ru or http://195.239.62.97/default.htm!';
  memSubstitutionTemplate.Text :=
   'The protocol is $1'#$d#$a
   + 'the address is $2'#$d#$a
   + 'the whole URL of our site is $&.';
  edReplaceString.Text := '$2';
  chkUseSubstitution.Checked := True;
  r.ModifierStr := 'xis-m';
  UpdateModifiers;
 end;

procedure TfmTestRE.btnSaintPetersburgClick(Sender: TObject);
 begin
  edRegExpr.Text :=
     '# Place modifier (?i) before subexpression (move outside) and'#$d#$a
   + '# the expression will match first occurence in example'#$d#$a
   + '((?i)Saint-)?Petersburg';
  edInputString.Text :=
   'Welcome to petersburg! Saint-Petersburg is a wondeful city'#$d#$a
   + ' - look at photos on my homepage http://anso.da.ru';
  memSubstitutionTemplate.Text := 'The name of city is $&.';
  edReplaceString.Text := 'The City';
  chkUseSubstitution.Checked := False;
  r.ModifierStr := 'x-i';
  UpdateModifiers;
 end;

procedure TfmTestRE.btnTemplateRomanNumberClick(Sender: TObject);
 begin
  edRegExpr.Text := '^(?i)M*(D?C{0,3}|C[DM])(L?X{0,3}|X[LC])(V?I{0,3}|I[VX])$';
  edInputString.Text :=
   'MCMXCIX';
  memSubstitutionTemplate.Text := '1999 is $& in roman numbers.';
  edReplaceString.Text := '<here was digit>';
  chkUseSubstitution.Checked := False;
  r.ModifierStr := '-x';
  UpdateModifiers;
 end;

procedure TfmTestRE.btnBackRefClick(Sender: TObject);
 begin
  edRegExpr.Text := '(?i)<font size=([''"]?)([+-]?\d+)\1>';
  edInputString.Text :=
   '<font size="+1"> big </font> <font size=1> very small</font>';
  memSubstitutionTemplate.Text := 'font size = $2 (extracted from tag: "$&").';
  edReplaceString.Text := '<font size=7>';
  chkUseSubstitution.Checked := False;
  r.ModifierStr := '-x';
  UpdateModifiers;
 end;

procedure TfmTestRE.btnNonGreedyClick(Sender: TObject);
 begin
  edRegExpr.Text := '<script([^>]*?)>(.*?)</script>';
  edInputString.Text :=
     '<script param1>Script1</script>'#$d#$a
   + '<script param2>'#$d#$a
   + '  Script2, will be merged with Script1'#$d#$a
   + '  if replace "*?" with "*"!'#$d#$a
   + '</script>';
  memSubstitutionTemplate.Text := 'Script block:'#$d#$a'"$&"'#$d#$a#$d#$a
  +'Params: "$1"'#$d#$a'Body: "$2"';
  edReplaceString.Text := '<!-- $& -- >';
  chkUseSubstitution.Checked := True;
  r.ModifierStr := 's-x';
  UpdateModifiers;
 end;

procedure TfmTestRE.HighlightREInFileViewer (AFileViewer : TfmFileViewer);
 begin
  with AFileViewer do begin
    RichEdit1.SelectAll;
    RichEdit1.SelAttributes.Color := clBlack;
    r.Expression := edRegExpr.Text;
    if r.Exec (RichEdit1.Lines.Text) then
      REPEAT
       RichEdit1.SelStart := r.MatchPos [0] - 1;
       RichEdit1.SelLength := r.MatchLen [0];
       RichEdit1.SelAttributes.Color := clRed;
      UNTIL not r.ExecNext;
    RichEdit1.SelLength := 0;
    lblRegExpr.Caption := r.Expression;
   end;
 end;

procedure TfmTestRE.btnFindRegExprInFileClick(Sender: TObject);
 var
  FV : TfmFileViewer;
 begin
  if OpenDialog1.Execute then begin
    FV := TfmFileViewer.Create (Application);
    with FV do begin
      Caption := Caption + ' ' + OpenDialog1.FileName;
      RichEdit1.Lines.LoadFromFile (OpenDialog1.FileName);
      Show;
     end;
    HighlightREInFileViewer (FV);
   end;
 end;


procedure TfmTestRE.btnReplaceClick(Sender: TObject);
 begin
  Compile;
  memReplaceResult.Text := r.Replace (edInputString.Text,
   edReplaceString.Text, chkUseSubstitution.Checked); //###0.947
 end;

procedure TfmTestRE.btnSplitClick(Sender: TObject);
 begin
  Compile;
  memSplitResult.Lines.Clear;
  r.Split (edInputString.Text, memSplitResult.Lines);
 end;

procedure TfmTestRE.chkModifierIClick(Sender: TObject);
 begin
  r.ModifierI := chkModifierI.Checked;
  // You may use also
  //   r.ModifierStr := 'i';
  // or
  //   r.ModifierStr := '-i';
 end;

procedure TfmTestRE.chkModifierRClick(Sender: TObject);
 begin
  r.ModifierR := chkModifierR.Checked;
 end;

procedure TfmTestRE.chkModifierSClick(Sender: TObject);
 begin
  r.ModifierS := chkModifierS.Checked;
 end;

procedure TfmTestRE.chkModifierGClick(Sender: TObject);
 begin
  r.ModifierG := chkModifierG.Checked;
 end;

procedure TfmTestRE.chkModifierMClick(Sender: TObject);
 begin
  r.ModifierM := chkModifierM.Checked;
 end;

procedure TfmTestRE.chkModifierXClick(Sender: TObject);
 begin
  r.ModifierX := chkModifierX.Checked;
 end;

procedure TfmTestRE.InputStringPosIsChanged;
 begin
  if edInputString.SelLength <= 0
   then edInputStringPos.Text := IntToStr (edInputString.SelStart + 1)
   else edInputStringPos.Text := IntToStr (edInputString.SelStart + 1)
      + ' - ' + IntToStr (edInputString.SelStart + edInputString.SelLength);
 end;

procedure TfmTestRE.RegExprChanged (AShowErrorPos : boolean = false);
 var
  i : integer;
  n : integer;
  s : string;
 begin
  n := RegExprSubExpressions (edRegExpr.Text, cbSubExprs.Items);
  case n of //###0.942
    0: lblRegExprUnbalancedBrackets.Caption := ''; // No errors
   -1: lblRegExprUnbalancedBrackets.Caption := 'Not enough ")"';
    else begin
      if n < 0 then begin
         s := 'No "]" found for "["';
         n := Abs (n) - 1;
        end
       else s := 'Unexpected ")"';
      if AShowErrorPos then begin
         s := s + ' at pos ' + IntToStr (n);
         edRegExpr.SetFocus;
         edRegExpr.SelStart := n - 1;
         edRegExpr.SelLength := 1;
        end
       else s := s + '. Doubleclick here!';
      lblRegExprUnbalancedBrackets.Caption := s;
     end;
   end;
  with cbSubExprs.Items do
   for i := 0 to Count - 1 do
    Strings [i] := '$' + IntToStr (i) + ': ' + Strings [i];

  RegExprPosIsChanged;
 end;

procedure TfmTestRE.RegExprPosIsChanged;
 var
  i : integer;
  CurrentPos : integer;
  SEStart, SELen : integer;
  MinSEIdx : integer;
  MinSELen : integer;
 begin
  MinSEIdx := -1;
  MinSELen := MaxInt;
  CurrentPos := edRegExpr.SelStart + 1;
  with cbSubExprs.Items do begin
    for i := 0 to Count - 1 do begin
      SEStart := integer (Objects [i]) and $FFFF;
      SELen := (integer (Objects [i]) ShR 16) and $FFFF;
      if (SEStart <= CurrentPos) and (SEStart + SELen > CurrentPos)
        and (MinSELen > SELen)
       then begin
         MinSEIdx := i;
         MinSELen := SELen;
        end;
     end;
    if (MinSEIdx >= 0) and (MinSEIdx < Count)
     then cbSubExprs.ItemIndex := MinSEIdx;
   end;
 end;

procedure TfmTestRE.SubexprSelected;
 var
  n : integer;
 begin
  if cbSubExprs.ItemIndex < cbSubExprs.Items.Count then begin
    n := integer (cbSubExprs.Items.Objects [cbSubExprs.ItemIndex]);
    edRegExpr.SetFocus;
    edRegExpr.SelStart := n and $FFFF - 1;
    edRegExpr.SelLength := (n ShR 16) and $FFFF;
   end;
 end;

procedure TfmTestRE.SubStringSelected;
 var
  n : integer;
 begin
  if cbSubStrs.ItemIndex < cbSubStrs.Items.Count then begin
    n := integer (cbSubStrs.Items.Objects [cbSubStrs.ItemIndex]);
    edInputString.SetFocus;
    edInputString.SelStart := n and $FFFF - 1;
    edInputString.SelLength := (n ShR 16) and $FFFF;
    InputStringPosIsChanged;
   end;
 end;

procedure TfmTestRE.edRegExprChange(Sender: TObject);
 begin
  RegExprChanged;
 end;

procedure TfmTestRE.cbSubExprsClick(Sender: TObject);
 begin
  SubexprSelected;
 end;

procedure TfmTestRE.edInputStringClick(Sender: TObject);
 begin
  InputStringPosIsChanged;
 end;

procedure TfmTestRE.edInputStringKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
 begin
  InputStringPosIsChanged;
 end;

procedure TfmTestRE.edInputStringMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
 begin
  InputStringPosIsChanged;
 end;

procedure TfmTestRE.edInputStringMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
 begin
  InputStringPosIsChanged;
 end;

procedure TfmTestRE.edRegExprClick(Sender: TObject);
 begin
  RegExprPosIsChanged;
 end;

procedure TfmTestRE.lblRegExprUnbalancedBracketsDblClick(Sender: TObject);
 begin
  RegExprChanged (True);
 end;

procedure TfmTestRE.edRegExprKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
 begin
  RegExprPosIsChanged;
 end;

procedure TfmTestRE.cbSubStrsClick(Sender: TObject);
 begin
  SubStringSelected;
 end;

procedure TfmTestRE.GoToRegExprHomePage;
 var
  zFileName, zParams, zDir: array [0 .. MAX_PATH] of Char;
 begin
  ShellExecute (
    Application.MainForm.Handle,
    nil,
    StrPCopy (zFileName, 'http://anso.virtualave.net/'),
    StrPCopy (zParams, ''),
    StrPCopy (zDir, ''), SW_SHOWNOACTIVATE);
 end;

procedure TfmTestRE.HelpLanguageSelected;
 var
  ExeFolder : string;
 begin
  ExeFolder := ExtractFilePath (Application.ExeName);
  case cbHelpLanguage.ItemIndex of
    0: Application.HelpFile := ExeFolder + 'RegExpRu.hlp';
    1: Application.HelpFile := ExeFolder + 'RegExpE.hlp';
    2: Application.HelpFile := ExeFolder + 'RegExpBG.hlp';
    3: Application.HelpFile := ExeFolder + 'RegExpG.hlp';
    4: Application.HelpFile := ExeFolder + 'RegExpF.hlp';
    5: Application.HelpFile := ExeFolder + 'RegExpS.hlp';
   end;
 end;

procedure TfmTestRE.btnHelpClick(Sender: TObject);
 begin
  HelpLanguageSelected;
  if not FileExists (Application.HelpFile) then begin
    case Application.MessageBox (
     PChar ('The help in language You''ve selected is not found'
     + ' at the "' + ExtractFilePath (Application.HelpFile) + '".'#$d#$a#$d#$a
     + 'Press Yes if You want to go to my home page to obtain it,'
     + ' or Press No if it stored in different folder at Your computer,'
     + ' or press Cancel to cancel the action.'),
     PChar ('Cannot find help file "' + Application.HelpFile + '"'),
     MB_YESNOCANCEL or MB_ICONQUESTION) of
      IDYES: begin
        GoToRegExprHomePage;
        EXIT;
       end;
      IDNO:; // just skip it thru windows help system - it will ask user for help file path
      else EXIT; // must be cancel or error in showing of the message box
     end;
   end;
  Application.HelpCommand (HELP_FINDER, 0);
 end;

procedure TfmTestRE.cbHelpLanguageClick(Sender: TObject);
 begin
  HelpLanguageSelected;
 end;

procedure TfmTestRE.lblWWWClick(Sender: TObject);
 begin
  GoToRegExprHomePage;
 end;


end.

