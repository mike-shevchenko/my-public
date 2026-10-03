
{*****************************************************************************}
{                                                                             }
{    Tnt Delphi Unicode Controls                                              }
{      http://home.ccci.org/wolbrink/tnt/delphi_unicode_controls.htm          }
{        Version: 2.0.23                                                      }
{                                                                             }
{    Copyright (c) 2002, 2003 Troy Wolbrink (troy.wolbrink@ccci.org)          }
{                                                                             }
{*****************************************************************************}

unit TntDialogs;

{$INCLUDE TntCompilers.inc}

interface

{$IFDEF COMPILER_6_UP}
{$WARN UNIT_PLATFORM OFF}
{$ENDIF}

uses
  Classes, SysUtils, Controls, Forms, Messages, Dlgs, CommDlg, Windows, Dialogs,
  TntClasses, TntControls;

type
{TNT-WARN TIncludeItemEvent}
  TIncludeItemEventW = procedure (const OFN: TOFNotifyExW; var Include: Boolean) of object;

{TNT-WARN TOpenDialog}
  TTntOpenDialog = class(TOpenDialog{TNT-ALLOW TOpenDialog})
  private
    FDefaultExt: WideString;
    FFileName: WideString;
    FFilter: WideString;
    FInitialDir: WideString;
    FTitle: WideString;
    FFiles: TTntStrings;
    FOnIncludeItem: TIncludeItemEventW;
    function GetDefaultExt: WideString;
    procedure SetInheritedDefaultExt(const Value: AnsiString);
    procedure SetDefaultExt(const Value: WideString);
    function GetFileName: WideString;
    procedure SetFileName(const Value: WideString);
    function GetFilter: WideString;
    procedure SetInheritedFilter(const Value: AnsiString);
    procedure SetFilter(const Value: WideString);
    function GetInitialDir: WideString;
    procedure SetInheritedInitialDir(const Value: AnsiString);
    procedure SetInitialDir(const Value: WideString);
    function GetTitle: WideString;
    procedure SetInheritedTitle(const Value: AnsiString);
    procedure SetTitle(const Value: WideString);
    function GetFiles: TTntStrings;
  private
    FProxiedOpenFilenameA: TOpenFilenameA;
  protected
    procedure DefineProperties(Filer: TFiler); override;
    function CanCloseW(var OpenFileName: TOpenFileNameW): Boolean;
    procedure GetFileNamesW(var OpenFileName: TOpenFileNameW);
    procedure DoIncludeItem(const OFN: TOFNotifyEx; var Include: Boolean); override;
    procedure WndProc(var Message: TMessage); override;
    function DoExecuteW(Func: Pointer): Bool;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Execute: Boolean; override;
    property Files: TTntStrings read GetFiles;
  published
    property DefaultExt: WideString read GetDefaultExt write SetDefaultExt;
    property FileName: WideString read GetFileName write SetFileName;
    property Filter: WideString read GetFilter write SetFilter;
    property InitialDir: WideString read GetInitialDir write SetInitialDir;
    property Title: WideString read GetTitle write SetTitle;
    property OnIncludeItem: TIncludeItemEventW read FOnIncludeItem write FOnIncludeItem;
  end;

{TNT-WARN TSaveDialog}
  TTntSaveDialog = class(TTntOpenDialog)
  public
    function Execute: Boolean; override;
  end;

{TNT-WARN InputQuery}
function WideInputQuery(const ACaption, APrompt: WideString;
   var Value: WideString): Boolean;

//------------------------------------------------------------------------------
//                         Tnt - FileCtrl
//------------------------------------------------------------------------------

{TNT-WARN SelectDirectory}
function WideSelectDirectory(const Caption: WideString; const Root: WideString;
  var Directory: WideString): Boolean;

implementation

uses
  {$IFDEF COMPILER_6_UP} Types, {$ENDIF} TntWindows, TntSysUtils, ActiveX, ShlObj, ShellApi,
  FileCtrl, TntForms, TntStdCtrls, Graphics, Consts;

var
  ProxyExecuteDialog: TTntOpenDialog;

function ProxyGetOpenFileNameA(var OpenFile: TOpenFilename): Bool; stdcall;
begin
  ProxyExecuteDialog.FProxiedOpenFilenameA := OpenFile;
  Result := False; { as if user hit "Cancel". }
end;

{ TTntOpenDialog }

constructor TTntOpenDialog.Create(AOwner: TComponent);
begin
  inherited;
  FFiles := TTntStringList.Create;
end;

destructor TTntOpenDialog.Destroy;
begin
  FreeAndNil(FFiles);
  inherited;
end;

procedure TTntOpenDialog.DefineProperties(Filer: TFiler);
begin
  inherited;
  TntPersistent_AfterInherited_DefineProperties(Filer, Self);
end;

function TTntOpenDialog.GetDefaultExt: WideString;
begin
  Result := GetSyncedWideString(FDefaultExt, inherited DefaultExt);
end;

procedure TTntOpenDialog.SetInheritedDefaultExt(const Value: AnsiString);
begin
  inherited DefaultExt := Value;
end;

procedure TTntOpenDialog.SetDefaultExt(const Value: WideString);
begin
  SetSyncedWideString(Value, FDefaultExt, inherited DefaultExt, SetInheritedDefaultExt);
end;

function TTntOpenDialog.GetFileName: WideString;
var
  Path: array[0..MAX_PATH] of WideChar;
begin
  if Win32PlatformIsUnicode and NewStyleControls and (Handle <> 0) then begin
    // get filename from handle
    SendMessageW(GetParent(Handle), CDM_GETFILEPATH, SizeOf(Path), Integer(@Path));
    Result := Path;
  end else
    Result := GetSyncedWideString(FFileName, inherited FileName);
end;

procedure TTntOpenDialog.SetFileName(const Value: WideString);
begin
  FFileName := Value;
  inherited FileName := Value;
end;

function TTntOpenDialog.GetFilter: WideString;
begin
  Result := GetSyncedWideString(FFilter, inherited Filter);
end;

procedure TTntOpenDialog.SetInheritedFilter(const Value: AnsiString);
begin
  inherited Filter := Value;
end;

procedure TTntOpenDialog.SetFilter(const Value: WideString);
begin
  SetSyncedWideString(Value, FFilter, inherited Filter, SetInheritedFilter);
end;

function TTntOpenDialog.GetInitialDir: WideString;
begin
  Result := GetSyncedWideString(FInitialDir, inherited InitialDir);
end;

procedure TTntOpenDialog.SetInheritedInitialDir(const Value: AnsiString);
begin
  inherited InitialDir := Value;
end;

procedure TTntOpenDialog.SetInitialDir(const Value: WideString);

  function RemoveTrailingPathDelimiter(const Value: WideString): WideString;
  var
    L: Integer;
  begin
    // remove trailing path delimiter (except 'C:\')
    L := Length(Value);
    if (L > 1) and WideIsPathDelimiter(Value, L) and not WideIsDelimiter(':', Value, L - 1) then
      Dec(L);
    Result := Copy(Value, 1, L);
  end;

begin
  SetSyncedWideString(RemoveTrailingPathDelimiter(Value), FInitialDir,
    inherited InitialDir, SetInheritedInitialDir);
end;

function TTntOpenDialog.GetTitle: WideString;
begin
  Result := GetSyncedWideString(FTitle, inherited Title)
end;

procedure TTntOpenDialog.SetInheritedTitle(const Value: AnsiString);
begin
  inherited Title := Value;
end;

procedure TTntOpenDialog.SetTitle(const Value: WideString);
begin
  SetSyncedWideString(Value, FTitle, inherited Title, SetInheritedTitle);
end;

function TTntOpenDialog.GetFiles: TTntStrings;
begin
  if (not Win32PlatformIsUnicode) then
    FFiles.Assign(inherited Files);
  Result := FFiles;
end;

function TTntOpenDialog.CanCloseW(var OpenFileName: TOpenFileNameW): Boolean;
begin
  GetFileNamesW(OpenFileName);
  Result := DoCanClose;
  FFiles.Clear;
  inherited Files.Clear;
end;

procedure TTntOpenDialog.DoIncludeItem(const OFN: TOFNotifyEx; var Include: Boolean);
begin
  // CDN_INCLUDEITEM -> DoIncludeItem() is only be available on Windows 2000 +
  // Therefore, just cast OFN as a TOFNotifyExW, since that's what it really is.
  if Win32PlatformIsUnicode and Assigned(FOnIncludeItem) then
    FOnIncludeItem(TOFNotifyExW(OFN), Include)
end;

procedure TTntOpenDialog.WndProc(var Message: TMessage);
begin
  Message.Result := 0;
  if (Message.Msg = WM_INITDIALOG) and not (ofOldStyleDialog in Options) then begin
    { If not ofOldStyleDialog then DoShow on CDN_INITDONE, not WM_INITDIALOG }
    Exit;
  end;
  if Win32PlatformIsUnicode
  and (Message.Msg = WM_NOTIFY) then begin
    case (POFNotify(Message.LParam)^.hdr.code) of
      CDN_FILEOK:
        if not CanCloseW(POFNotifyW(Message.LParam)^.lpOFN^) then
        begin
          Message.Result := 1;
          SetWindowLong(Handle, DWL_MSGRESULT, Message.Result);
          Exit;
        end;
    end;
  end;
  inherited WndProc(Message);
end;

function TTntOpenDialog.DoExecuteW(Func: Pointer): Bool;
var
  OpenFilename: TOpenFilenameW;

  function GetResNamePtr(var ScopedStringStorage: WideString; lpszName: PAnsiChar): PWideChar;
  // duplicated from TntTrxResourceUtils.pas
  begin
    if Tnt_Is_IntResource(PWideChar(lpszName)) then
      Result := PWideChar(lpszName)
    else begin
      ScopedStringStorage := lpszName;
      Result := PWideChar(ScopedStringStorage);
    end;
  end;

  function AllocFilterStr(const S: WideString): WideString;
  var
    P: PWideChar;
  begin
    Result := '';
    if S <> '' then
    begin
      Result := S + #0#0;  // double null terminators (an additional zero added in case Description/Filter pair not even.)
      P := StrScanW(PWideChar(Result), '|');
      while P <> nil do
      begin
        P^ := #0;
        Inc(P);
        P := StrScanW(P, '|');
      end;
    end;
  end;

var
  TempTemplate, TempFilter, TempFilename, TempExt: WideString;
begin
  FFiles.Clear;

  // 1. Init inherited dialog defaults.
  // 2. Populate OpenFileName record with ansi defaults
  ProxyExecuteDialog := Self;
  try
    DoExecute(@ProxyGetOpenFileNameA);
  finally
    ProxyExecuteDialog := nil;
  end;
  OpenFileName := TOpenFilenameW(FProxiedOpenFilenameA);

  with OpenFilename do
  begin
    // Filter (PChar -> PWideChar)
    TempFilter := AllocFilterStr(Filter);
    lpstrFilter := PWideChar(TempFilter);
    // FileName (PChar -> PWideChar)
    SetLength(TempFilename, nMaxFile + 2);
    lpstrFile := PWideChar(TempFilename);
    FillChar(lpstrFile^, (nMaxFile + 2) * SizeOf(WideChar), 0);
    StrLCopyW(lpstrFile, PWideChar(FileName), nMaxFile);
    // InitialDir (PChar -> PWideChar)
    if (InitialDir = '') and ForceCurrentDirectory then
      lpstrInitialDir := '.'
    else
      lpstrInitialDir := PWideChar(InitialDir);
    // Title (PChar -> PWideChar)
    lpstrTitle := PWideChar(Title);
    // DefaultExt (PChar -> PWideChar)
    TempExt := DefaultExt;
    if (TempExt = '') and (Flags and OFN_EXPLORER = 0) then
    begin
      TempExt := WideExtractFileExt(Filename);
      Delete(TempExt, 1, 1);
    end;
    if TempExt <> '' then
      lpstrDefExt := PWideChar(TempExt);
    // resource template (PChar -> PWideChar)
    lpTemplateName := GetResNamePtr(TempTemplate, Template);
    // start modal dialog
    Result := TaskModalDialog(Func, OpenFileName);
    if Result then
    begin
      GetFileNamesW(OpenFilename);
      if (Flags and OFN_EXTENSIONDIFFERENT) <> 0 then
        Options := Options + [ofExtensionDifferent]
      else
        Options := Options - [ofExtensionDifferent];
      if (Flags and OFN_READONLY) <> 0 then
        Options := Options + [ofReadOnly]
      else
        Options := Options - [ofReadOnly];
      FilterIndex := nFilterIndex;
    end;
  end;
end;

procedure TTntOpenDialog.GetFileNamesW(var OpenFileName: TOpenFileNameW);
var
  Separator: WideChar;

  procedure ExtractFileNamesW(P: PWideChar);
  var
    DirName, FileName: WideString;
    FileList: TWideStringDynArray;
    i: integer;
  begin
    FileList := ExtractStringsFromStringArray(P, Separator);
    if Length(FileList) > 0 then begin
      DirName := FileList[0];
      if Length(FileList) = 1 then
        FFiles.Add(DirName)
      else begin
        // prepare DirName
        if WideLastChar(DirName) <> PathDelim then
          DirName := DirName + PathDelim;
        // add files
        for i := 1 {second item} to High(FileList) do begin
          FileName := FileList[i];
          // prepare FileName
          if (FileName[1] <> PathDelim)
          and ((Length(FileName) <= 3) or (FileName[2] <> DriveDelim) or (FileName[3] <> PathDelim))
          then
            FileName := DirName + FileName;
          // add to list
          FFiles.Add(FileName);
        end;
      end;
    end;
  end;

var
  P: PWideChar;
begin
  Separator := #0;
  if (ofAllowMultiSelect in Options) and
    ((ofOldStyleDialog in Options) or not NewStyleControls) then
    Separator := ' ';
  with OpenFileName do
  begin
    if ofAllowMultiSelect in Options then
    begin
      ExtractFileNamesW(lpstrFile);
      FileName := FFiles[0];
    end else
    begin
      P := lpstrFile;
      FileName := ExtractStringFromStringArray(P, Separator);
      FFiles.Add(FileName);
    end;
  end;

  // Sync inherited Files
  inherited Files.Assign(FFiles);
end;

function TTntOpenDialog.Execute: Boolean;
begin
  if (not Win32PlatformIsUnicode) then
    Result := DoExecute(@GetOpenFileNameA)
  else
    Result := DoExecuteW(@GetOpenFileNameW);
end;

{ TTntSaveDialog }

function TTntSaveDialog.Execute: Boolean;
begin
  if (not Win32PlatformIsUnicode) then
    Result := DoExecute(@GetSaveFileNameA)
  else
    Result := DoExecuteW(@GetSaveFileNameW);
end;

{ WideInputQuery }

function WideInputQuery(const ACaption, APrompt: WideString; var Value: WideString): Boolean;
var
  Form: TTntForm{TNT-ALLOW TTntForm};
  Prompt: TTntLabel;
  Edit: TTntEdit;
  DialogUnits: TPoint;
  ButtonTop, ButtonWidth, ButtonHeight: Integer;


    function GetAveCharSize(Canvas: TCanvas): TPoint;
    var
      I: Integer;
      Buffer: array[0..51] of WideChar;
    begin
      for I := 0 to 25 do Buffer[I] := WideChar(I + Ord('A'));
      for I := 0 to 25 do Buffer[I + 26] := WideChar(I + Ord('a'));
      GetTextExtentPointW(Canvas.Handle, Buffer, 52, TSize(Result));
      Result.X := Result.X div 52;
    end;

begin
  Result := False;
  Form := TTntForm{TNT-ALLOW TTntForm}.Create(Application);
  with Form do begin
    try
      Canvas.Font := Font;
      DialogUnits := GetAveCharSize(Canvas);
      BorderStyle := bsDialog;
      Caption := ACaption;
      ClientWidth := MulDiv(180, DialogUnits.X, 4);
      ClientHeight := MulDiv(63, DialogUnits.Y, 8);
      Position := poScreenCenter;
      Prompt := TTntLabel.Create(Form);
      with Prompt do
      begin
        Parent := Form;
        AutoSize := True;
        Left := MulDiv(8, DialogUnits.X, 4);
        Top := MulDiv(8, DialogUnits.Y, 8);
        Caption := APrompt;
      end;
      Edit := TTntEdit.Create(Form);
      with Edit do
      begin
        Parent := Form;
        Left := Prompt.Left;
        Top := MulDiv(19, DialogUnits.Y, 8);
        Width := MulDiv(164, DialogUnits.X, 4);
        MaxLength := 255;
        Text := Value;
        SelectAll;
      end;
      ButtonTop := MulDiv(41, DialogUnits.Y, 8);
      ButtonWidth := MulDiv(50, DialogUnits.X, 4);
      ButtonHeight := MulDiv(14, DialogUnits.Y, 8);
      with TTntButton.Create(Form) do
      begin
        Parent := Form;
        Caption := SMsgDlgOK;
        ModalResult := mrOk;
        Default := True;
        SetBounds(MulDiv(38, DialogUnits.X, 4), ButtonTop, ButtonWidth,
          ButtonHeight);
      end;
      with TTntButton.Create(Form) do
      begin
        Parent := Form;
        Caption := SMsgDlgCancel;
        ModalResult := mrCancel;
        Cancel := True;
        SetBounds(MulDiv(92, DialogUnits.X, 4), ButtonTop, ButtonWidth,
          ButtonHeight);
      end;
      if ShowModal = mrOk then
      begin
        Value := Edit.Text;
        Result := True;
      end;
    finally
      Form.Free;
    end;
  end;
end;

//------------------------------------------------------------------------------
//                         Tnt - FileCtrl
//------------------------------------------------------------------------------

function SelectDirCB_W(Wnd: HWND; uMsg: UINT; lParam, lpData: LPARAM): Integer stdcall;
begin
  if (uMsg = BFFM_INITIALIZED) and (lpData <> 0) then
    SendMessageW(Wnd, BFFM_SETSELECTIONW, Integer(True), lpdata);
  result := 0;
end;

function WideSelectDirectory(const Caption: WideString; const Root: WideString;
  var Directory: WideString): Boolean;
const
  BIF_NEWDIALOGSTYLE = $0040;
  BIF_USENEWUI = (BIF_NEWDIALOGSTYLE or BIF_EDITBOX);
var
  WindowList: Pointer;
  BrowseInfo: TBrowseInfoW;
  Buffer: PWideChar;
  OldErrorMode: Cardinal;
  RootItemIDList, ItemIDList: PItemIDList;
  ShellMalloc: IMalloc;
  IDesktopFolder: IShellFolder;
  Eaten, Flags: LongWord;
  AnsiDirectory: AnsiString;
begin
  if (not Win32PlatformIsUnicode) then begin
    AnsiDirectory := Directory;
    Result := SelectDirectory{TNT-ALLOW SelectDirectory}(Caption, Root, AnsiDirectory);
    Directory := AnsiDirectory;
  end else begin
    Result := False;
    if not WideDirectoryExists(Directory) then
      Directory := '';
    FillChar(BrowseInfo, SizeOf(BrowseInfo), 0);
    if (ShGetMalloc(ShellMalloc) = S_OK) and (ShellMalloc <> nil) then
    begin
      Buffer := ShellMalloc.Alloc(MAX_PATH * SizeOf(WideChar));
      try
        RootItemIDList := nil;
        if Root <> '' then
        begin
          SHGetDesktopFolder(IDesktopFolder);
          IDesktopFolder.ParseDisplayName(Application.Handle, nil,
            POleStr(Root), Eaten, RootItemIDList, Flags);
        end;
        with BrowseInfo do
        begin
          hwndOwner := Application.Handle;
          pidlRoot := RootItemIDList;
          pszDisplayName := Buffer;
          lpszTitle := PWideChar(Caption);
          ulFlags := BIF_RETURNONLYFSDIRS;
          if Win32MajorVersion >= 5 then
            ulFlags := ulFlags or BIF_USENEWUI;
          if Directory <> '' then
          begin
            lpfn := SelectDirCB_W;
            lParam := Integer(PWideChar(Directory));
          end;
        end;
        WindowList := DisableTaskWindows(0);
        OldErrorMode := SetErrorMode(SEM_FAILCRITICALERRORS);
        try
          ItemIDList := Tnt_ShBrowseForFolderW(BrowseInfo);
        finally
          SetErrorMode(OldErrorMode);
          EnableTaskWindows(WindowList);
        end;
        Result :=  ItemIDList <> nil;
        if Result then
        begin
          Win32Check(Tnt_ShGetPathFromIDListW(ItemIDList, Buffer));
          ShellMalloc.Free(ItemIDList);
          Directory := Buffer;
        end;
      finally
        ShellMalloc.Free(Buffer);
      end;
    end;
  end;
end;

end.
