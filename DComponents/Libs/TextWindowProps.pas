unit TextWindowProps;

interface

uses
  Graphics, StdCtrls, ComCtrls;

//======================================================================================================================
var
//----------------------------------------------------------------------------------------------------------------------

  FontName:  string = 'Courier New';
  FontSize:  Integer = 10;
  FontColor: TColor = clWindowText;
  BgColor:   TColor = clWindow;

//======================================================================================================================
// Utilities
//----------------------------------------------------------------------------------------------------------------------

procedure TuneFont(Font: TFont);
procedure TuneMemo(Memo: TMemo);
procedure TuneRichEdit(RichEdit: TRichEdit);

//======================================================================================================================
implementation /////////////////////////////////////////////////////////////////////////////////////////////////////////
//----------------------------------------------------------------------------------------------------------------------

uses
  Windows, Registry, SysUtils;

//======================================================================================================================
// Utilities
//----------------------------------------------------------------------------------------------------------------------

procedure TuneFont(Font: TFont);

begin
  Font.Name := FontName;
  Font.Size := FontSize;
  Font.Color := FontColor;
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TuneMemo(Memo: TMemo);

begin
  TuneFont(Memo.Font);
  Memo.Color := BgColor;
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TuneRichEdit(RichEdit: TRichEdit);

begin
  TuneFont(RichEdit.Font);
  RichEdit.Color := BgColor;
end;

//======================================================================================================================
var
//----------------------------------------------------------------------------------------------------------------------

  Registry: TRegistry;

//======================================================================================================================
initialization
//----------------------------------------------------------------------------------------------------------------------

  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if not Registry.OpenKey('\Software\mikeshevchen\TextWindowProps', {Cancreate}False) then Exit;

    try
      FontName := Registry.ReadString('FontName');
      FontSize := Registry.ReadInteger('FontSize');
      FontColor := Registry.ReadInteger('FontColor');
      BgColor := Registry.ReadInteger('BgColor');
    except
      MessageBox(0, PChar(Exception(ExceptObject).Message), 'TextWindowProps', MB_ICONERROR);
    end;

  finally
    Registry.Free;
  end;

//======================================================================================================================
end.


