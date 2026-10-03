unit FntFiles;

interface

uses
  Classes, Contnrs, SysUtils,
  RasterChars;

//======================================================================================================================
type
//----------------------------------------------------------------------------------------------------------------------

  TFontFamily =
  (
    cFontFamily_DontCare,
    cFontFamily_Roman,
    cFontFamily_Swiss,
    cFontFamily_Modern,
    cFontFamily_Script,
    cFontFamily_Decorative
  );

//----------------------------------------------------------------------------------------------------------------------

  EFontIsVector = class(Exception)
    {EMPTY}
  end;

  EUnsupportedFontVersion = class(Exception)
    {EMPTY}
  end;

//----------------------------------------------------------------------------------------------------------------------

  TFntFile = class

  private
    FFaceName: string;
    FCopyright: string;
    FPoints: Word;
    FVertRes: Word;
    FHorizRes: Word;
    FAscent: Word;
    FIntLeading: Word;
    FExtLeading: Word;
    FItalic: Boolean;
    FUnderline: Boolean;
    FStrikeOut: Boolean;
    FWeight: Word;
    FCharSet: Word;
    FPixWidth: Word;
    FFixedPitch: Boolean;
    FFamily: TFontFamily;
    FAvgWidth: Word;
    FMaxWidth: Word;
    FDefaultChar: Char;
    FBreakChar: Char;

    FFirstChar: Char;
    FRasterChars: TObjectList{of TRasterChar};

    constructor Create;

    function GetStreamSize: Word;

    procedure SetFirstChar(Value: Char);
    function GetRasterCharsCount: Integer;
    function GetRasterChars(I: Integer): TRasterChar;

    procedure SetCopyright(const Value: string);

  public
    constructor CreateDefault(FirstChar: Char; CharsCount: Integer; Width, Height: Integer);
    constructor CreateFromStream(Stream: TStream);
    destructor Destroy; override;
    class function HeaderSize: Word;
    procedure WriteHeaderToStream(Stream: TStream);
    property StreamSize: Word read GetStreamSize;
    procedure WriteToStream(Stream: TStream);

    property FaceName: string read FFaceName write FFaceName;
    property Copyright: string read FCopyright write SetCopyright;
    property Points: Word read FPoints write FPoints;
    property VertRes: Word read FVertRes write FVertRes;
    property HorizRes: Word read FHorizRes write FHorizRes;
    property Ascent: Word read FAscent write FAscent;
    property IntLeading: Word read FIntLeading write FIntLeading;
    property ExtLeading: Word read FExtLeading write FExtLeading;
    property Italic: Boolean read FItalic write FItalic;
    property Underline: Boolean read FUnderline write FUnderline;
    property StrikeOut: Boolean read FStrikeOut write FStrikeOut;
    property Weight: Word read FWeight write FWeight;
    property CharSet: Word read FCharSet write FCharSet;
    property PixWidth: Word read FPixWidth write FPixWidth;
    property FixedPitch: Boolean read FFixedPitch write FFixedPitch;
    property Family: TFontFamily read FFamily write FFamily;
    property AvgWidth: Word read FAvgWidth write FAvgWidth;
    property MaxWidth: Word read FMaxWidth write FMaxWidth;
    property DefaultChar: Char read FDefaultChar write FDefaultChar;
    property BreakChar: Char read FBreakChar write FBreakChar;

    property FirstChar: Char read FFirstChar write SetFirstChar;
    property RasterCharsCount: Integer read GetRasterCharsCount;
    property RasterChars[I: Integer]: TRasterChar read GetRasterChars;

    procedure AppendNewChar(RasterChar: TRasterChar);
    procedure PrependNewChar(RasterChar: TRasterChar);
    procedure DeleteLastChar;
    procedure DeleteFirstChar;
  end;

//======================================================================================================================
implementation /////////////////////////////////////////////////////////////////////////////////////////////////////////
//----------------------------------------------------------------------------------------------------------------------

//======================================================================================================================
// Utilities
//----------------------------------------------------------------------------------------------------------------------

function ReadNullTermString(Stream: TStream): string;

var
  C: Char;

begin
  Result := '';
  while True do
  begin
    Stream.ReadBuffer(C, 1);
    if C = #0 then Break;
    Result := Result + C;
  end;
end;

//======================================================================================================================
type
//----------------------------------------------------------------------------------------------------------------------

  THeader = packed record

    dfVersion: Word;
    dfSize: Longword;
    dfCopyright: array [0..59] of Char;
    dfType: Word;
    dfPoints: Word;
    dfVertRez: Word;
    dfHorizRes: Word;
    dfAscent: Word;
    dfIntLeading: Word;
    dfExtLeading: Word;
    dfItalic: Byte;
    dfUnderline: Byte;
    dfStrikeOut: Byte;
    dfWeight: Word;
    dfCharSet: Byte;
    dfPixWidth: Word;
    dfPixHeight: Word;
    dfPitchFamily: Byte;
    dfAvgWidth: Word;
    dfMaxWidth: Word;
    dfFirstChar: Char;
    dfLastChar: Char;
    dfDefaultChar: Char;
    dfBreakChar: Char;
    dfWidthBytes: Word;
    dfDevice: Longword;
    dfFace: Longword;
    dfBitsPointer: Longword;
  end;

//======================================================================================================================
// TFntFile
//----------------------------------------------------------------------------------------------------------------------

constructor TFntFile.Create;

begin
  FRasterChars := TObjectList.Create;
end;

//----------------------------------------------------------------------------------------------------------------------

destructor TFntFile.Destroy;

begin
  FRasterChars.Free;
end;

//----------------------------------------------------------------------------------------------------------------------

constructor TFntFile.CreateDefault(FirstChar: Char; CharsCount: Integer; Width, Height: Integer);

var
  I: Integer;

begin
  Create;

  Assert(CharsCount > 0);
  Assert(Ord(FirstChar) + CharsCount <= 256);
  Assert(Width > 0);
  Assert(Height > 0);

  FFirstChar := FirstChar;

  for I := 0 to CharsCount-1 do
    FRasterChars.Add(TRasterChar.Create(Width, Height));
end;

//----------------------------------------------------------------------------------------------------------------------

constructor TFntFile.CreateFromStream(Stream: TStream); {raise EReadError, EFontIsVector, EUnsupportedFontVersion}

var
  Header: THeader;
  I: Integer;
  BitmapOfs: Longword;
  NotUsed: Byte;
  CharWidth: Word;
  CharOfs: Word;
  RasterChar: TRasterChar;
  X, Y: Integer;
  Position: Int64;
  CharBuffer: array of Byte;

begin
  Create;

  Stream.ReadBuffer(Header, SizeOf(Header));

  // Check Version:
  if (Header.dfVersion <> $200) and (Header.dfVersion <> $100) then
    raise EUnsupportedFontVersion.Create(IntToStr(Header.dfVersion));

  // Read Copyright:
  FCopyright := '';
  I := 0;
  while (I < 60) and (Header.dfCopyright[I] <> #0) do
  begin
    FCopyright := FCopyright + Header.dfCopyright[I];
    Inc(I);
  end;
  FCopyright := Trim(FCopyright);

  // Check Raster/Vector type:
  if (Header.dfType and 1) <> 0 then
    raise EFontIsVector.Create('');

  FPoints := Header.dfPoints;
  FVertRes := Header.dfVertRez;
  FHorizRes := Header.dfHorizRes;
  FAscent := Header.dfAscent;
  FIntLeading := Header.dfIntLeading;
  FExtLeading := Header.dfExtLeading;
  FItalic := (Header.dfItalic <> 0);
  FUnderline := (Header.dfUnderline <> 0);
  FStrikeOut := (Header.dfStrikeOut <> 0);
  FWeight := Header.dfWeight;
  FCharSet := Header.dfCharSet;
  FPixWidth := Header.dfPixWidth;
  FFixedPitch := (Header.dfPitchFamily and 1 = 0);
  FFamily := TFontFamily(Header.dfPitchFamily shr 4);
  FAvgWidth := Header.dfAvgWidth;
  FMaxWidth := Header.dfMaxWidth;
  FDefaultChar := Header.dfDefaultChar;
  FBreakChar := Header.dfBreakChar;
  FFirstChar := Header.dfFirstChar;

  Stream.ReadBuffer(BitmapOfs, 4);

  Stream.ReadBuffer(NotUsed, 1);

  for I := Ord(Header.dfFirstChar) to Ord(Header.dfLastChar) do
  begin
    Stream.ReadBuffer(CharWidth, 2);
    Stream.ReadBuffer(CharOfs, 2);

    RasterChar := TRasterChar.Create(CharWidth, Header.dfPixHeight);
    FRasterChars.Add(RasterChar);

    // Read character bitmap:
    Position := Stream.Position;
    Stream.Position := CharOfs;
    SetLength(CharBuffer, Header.dfPixHeight * (CharWidth + 7) div 8);
    Stream.ReadBuffer(CharBuffer[0], Length(CharBuffer));
    Stream.Position := Position;

    for X := 0 to CharWidth-1 do
      for Y := 0 to Header.dfPixHeight-1 do
      begin
        RasterChar.Pixels[X, Y] := Odd(
          CharBuffer[Header.dfPixHeight * (X div 8) + Y] shr (7 - X mod 8));
      end;
  end;

  Stream.Position := Header.dfFace;
  FFaceName := ReadNullTermString(Stream);
end;

//----------------------------------------------------------------------------------------------------------------------

class function TFntFile.HeaderSize: Word;

begin
  Result := SizeOf(THeader);
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TFntFile.WriteHeaderToStream(Stream: TStream);

var
  Header: THeader;
  I: Integer;

begin
  with Header do
  begin
    dfVersion := $200;

    dfSize := GetStreamSize;

    FillChar(dfCopyright[0], Length(dfCopyright), 0);
    Move(FCopyright[1], dfCopyright[0], Length(FCopyright));

    dfType := 0;

    dfPoints := FPoints;
    dfVertRez := FVertRes;
    dfHorizRes := FHorizRes;
    dfAscent := FAscent;
    dfIntLeading := FIntLEading;
    dfExtLeading := FExtLeading;
    dfItalic := Ord(FItalic);
    dfUnderline := Ord(FUnderline);
    dfStrikeOut := Ord(FStrikeOut);
    dfWeight := FWeight;
    dfCharSet := FCharSet;
    dfPixWidth := FPixWidth;

    Assert(RasterCharsCount > 0);

    dfPixHeight := RasterChars[0].Height;

    for I := 1 to RasterCharsCount-1 do
      Assert(RasterChars[I].Height = dfPixHeight, 'All RasterChars should have the same height.');

    dfPitchFamily := (Ord(FFamily) shl 4) or Ord(FFixedPitch);

    dfAvgWidth := FAvgWidth;
    dfMaxWidth := FMaxWidth;
    dfFirstChar := FFirstChar;

    dfLastChar := Chr(Ord(FFirstChar) + RasterCharsCount - 1);

    dfDefaultChar := FDefaultChar;
    dfBreakChar := FBreakChar;

    dfWidthBytes := {absolute-space char}1;
    for I := 0 to RasterCharsCount-1 do
      Inc(dfWidthBytes, (RasterChars[I].Width + 7) div 8);

    dfDevice := 0;

    dfFace := GetStreamSize - (Length(FFaceName) + {null-term}1);

    dfBitsPointer := 0;
  end;

  Stream.WriteBuffer(Header, SizeOf(Header));
end;

//----------------------------------------------------------------------------------------------------------------------

function TFntFile.GetStreamSize: Word;

var
  WidthBytes: Integer;
  I: Integer;

begin
  Assert(RasterCharsCount > 0);

  WidthBytes := {absolute-space char}1;
  for I := 0 to RasterCharsCount-1 do
    Inc(WidthBytes, (RasterChars[I].Width + 7) div 8);

  Result := HeaderSize + {BitmapOfs}4 + {NotUsed}1 +
    (RasterCharsCount + {absolute-space char}1) * ({Width}2 + {Ofs}2) +
    RasterChars[0].Height * WidthBytes +
    Length(FFaceName) + {null-term}1;
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TFntFile.WriteToStream(Stream: TStream);

var
  StreamStartPos: Int64;
  BitmapOfs: Longword;
  NotUsed: Byte;
  Width: Word;
  Ofs: Word;
  I: Integer;
  X: Integer;
  ColCount: Integer;
  ColWidth: Integer;
  Row, Col: Integer;
  B: Byte;
  AbsoluteSpaceCharBitmap: array of Byte;

begin
  StreamStartPos := Stream.Position;

  WriteHeaderToStream(Stream);

  BitmapOfs := HeaderSize + {BitmapOfs}4 + {NotUsed}1 +
    (RasterCharsCount + {absolute-space char}1) * ({Width}2 + {Ofs}2);
  Stream.WriteBuffer(BitmapOfs, 4);

  NotUsed := 0;
  Stream.WriteBuffer(NotUsed, 1);

  // Write width table:
  Ofs := BitmapOfs;
  for I := 0 to RasterCharsCount-1 do
  begin
    Width := RasterChars[I].Width;
    Stream.WriteBuffer(Width, 2);
    Stream.WriteBuffer(Ofs, 2);
    Inc(Ofs, RasterChars[I].Height * ((RasterChars[I].Width + 7) div 8));
  end;
  Width := {absolute-space char width}8;
  Stream.WriteBuffer(Width, 2);
  Stream.WriteBuffer(Ofs, 2);

  Assert(Stream.Position - StreamStartPos = BitmapOfs);

  // Write bitmap:
  for I := 0 to RasterCharsCount-1 do
  begin
    if RasterChars[I].Width > 0 then
    begin
      ColCount := (RasterChars[I].Width - 1) div 8 + 1;
      for Col := 0 to ColCount-1 do
        for Row := 0 to RasterChars[I].Height-1 do
        begin
          B := 0;

          if (Col < ColCount-1) or (RasterChars[I].Width mod 8 = 0) then
            ColWidth := 8
          else
            ColWidth := RasterChars[I].Width mod 8;

          for X := 0 to ColWidth-1 do
            B := B or (Ord(RasterChars[I].Pixels[Col * 8 + X, Row]) shl (7 - X));

          Stream.WriteBuffer(B, 1);
        end;
    end;
  end;

  // Write bitmap for absolute-space char:
  SetLength(AbsoluteSpaceCharBitmap, RasterChars[0].Height);
  FillChar(AbsoluteSpaceCharBitmap[0], Length(AbsoluteSpaceCharBitmap), 0);
  Stream.WriteBuffer(AbsoluteSpaceCharBitmap[0], Length(AbsoluteSpaceCharBitmap));

  Stream.WriteBuffer(FFaceName[1], Length(FFaceName) + {null-term}1);

  Assert(Stream.Position - StreamStartPos = StreamSize);
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TFntFile.SetFirstChar(Value: Char);

begin
  Assert(Ord(FFirstChar) + RasterCharsCount <= 256);

  FFirstChar := Value;
end;

//----------------------------------------------------------------------------------------------------------------------

function TFntFile.GetRasterCharsCount: Integer;

begin
  Result := FRasterChars.Count;
end;

//----------------------------------------------------------------------------------------------------------------------

function TFntFile.GetRasterChars(I: Integer): TRasterChar;

begin
  Assert(I >= 0);
  Assert(I < RasterCharsCount);

  Result := TRasterChar(FRasterChars[I]);
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TFntFile.AppendNewChar(RasterChar: TRasterChar);

begin
  Assert(Ord(FFirstChar) + RasterCharsCount < 256);

  FRasterChars.Add(RasterChar);
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TFntFile.PrependNewChar(RasterChar: TRasterChar);

begin
  Assert(Ord(FFirstChar) > 0);

  Dec(FFirstChar);
  FRasterChars.Insert(0, RasterChar);
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TFntFile.DeleteLastChar;

begin
  Assert(RasterCharsCount > 1);

  FRasterChars.Delete(FRasterChars.Count-1);
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TFntFile.DeleteFirstChar;

begin
  Assert(RasterCharsCount > 1);

  Inc(FFirstChar);
  FRasterChars.Delete(0);
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TFntFile.SetCopyright(const Value: string);

begin
  if Value = FCopyright then Exit;

  Assert(Length(Value) <= 60);

  FCopyright := Value;
end;

//======================================================================================================================
end.


