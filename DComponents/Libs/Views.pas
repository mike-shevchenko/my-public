unit Views;

{**********************************************************************}
{                                                                      }
{    Views v4.16  -  RGBColor Bitmap Processing Module                 }
{                                                                      }
{    Mikhail Shevchenko, mike.shevchenko@gmail.com                     }
{                                                                      }
{    Licensed under MPL 2.0: www.mozilla.org/MPL/2.0/                  }
{                                                                      }
{**********************************************************************}

{
  Contains necessary definitions for RGBColor graphics processing
  and a TView class that incapsulates 32-bit RGBColor TBitmap
  supporting additional features like scanline address caching.
  The class contains drawing methods for lines, rects etc. with
  auto-clipping capabilities.
}


interface


  uses
    Windows, Graphics, SysUtils, Classes;


// A fix for the error in 'Windows.pas': GetCharacterPlacementW
// uses TGCPResults (which is the same as TGCPResultsA) but should use TGCPResultsW.

type
  PGCP_RESULTSW = ^GCP_RESULTSW;
  GCP_RESULTSW = record
    lStructSize: DWORD;
    lpOutString: PWideChar;
    lpOrder: PUINT;
    lpDx: PINT;
    lpCaretPos: PINT;
    lpClass: PChar; // note: always PChar and not PWideChar
    lpGlyphs: PWideChar;
    nGlyphs: UINT;
    nMaxFit: Integer;
  end;

function GetCharacterPlacementW(
  hdc: HDC;                    // handle to DC
  lpString: PWideChar;         // character string
  nCount: Integer;             // number of characters
  nMaxExtent: Integer;         // maximum extent for string
  lpResults: PGCP_RESULTSW;    // placement result
  dwFlags: DWORD               // placement options
): DWORD; stdcall;             // 0 = OK else width/height of string.

// A fix for the constant value missing in 'Windows.pas'.
const
  CLEARTYPE_QUALITY = 5;


  type

    PRGBColor = ^TRGBColor;
    TRGBColor = packed record
    case Boolean of
      True:  ( B, G, R, Z: byte );
      False: ( C: LongWord );
    end;

    TYCCColor = packed record
    case Boolean of
      True:  ( R, B: shortint; Y, Z: byte );
      False: ( C: LongWord );
    end;


  function RGBColor ( R, G, B: byte;  Z: byte = 0 ): TRGBColor;
  function RGBColorAvg ( ColorA, ColorB: TRGBColor ): TRGBColor;
  function TRGBColorToTColor ( RGBColor: TRGBColor ): TColor;
  function TColorToTRGBColor ( Color: TColor ): TRGBColor;
  function TRGBColorToTYCCColor ( RGBColor: TRGBColor ): TYCCColor;
  function TYCCColorToTRGBColor ( YCCColor: TYCCColor ): TRGBColor;
  function TRGBColorToY ( RGBColor: TRGBColor ): Byte;



  const
    TrueDRed:    TRGBColor = (b:0;   g:0;   r:128; z:0);
    TrueLRed:    TRGBColor = (b:0;   g:0;   r:255; z:0);
    TrueDGreen:  TRGBColor = (b:0;   g:128; r:0;   z:0);
    TrueLGreen:  TRGBColor = (b:0;   g:255; r:0;   z:0);
    TrueDBlue:   TRGBColor = (b:128; g:0;   r:0;   z:0);
    TrueLBlue:   TRGBColor = (b:255; g:0;   r:0;   z:0);
    TrueWhite:   TRGBColor = (b:255; g:255; r:255; z:0);
    TrueBlack:   TRGBColor = (b:0;   g:0;   r:0;   z:0);
    TrueYellow:  TRGBColor = (b:0;   g:255; r:255; z:0);
    TrueLGray:   TRGBColor = (b:192; g:192; r:192; z:0);
    TrueDGray:   TRGBColor = (b:128; g:128; r:128; z:0);
    TrueMGray:   TRGBColor = (b:160; g:160; r:160; z:0);
    TrueBGray:   TRGBColor = (b:223; g:223; r:223; z:0);



  type

    PViewHistogram = ^TViewHistogram;
    TViewHistogram = array [0..255] of Integer;



  function ViewHistogramMax ( const Histogram: TViewHistogram ): Integer;



  type

    TCaretArray = array of Integer;


    TView = class ( TBitmap )
    private
      FLine:           array of PAnsiChar;
      FFontQuality:    Byte;
      FFontCharSet:    TFontCharSet;
      FFontSize:       Integer;
      FFontName:       string;
      FFontBold:       Boolean;
      FFontItalic:     Boolean;
      FFontUnderline:  Boolean;
      FFontColor:      TRGBColor;
      FFontLineHeight: Integer;
      FMFontSize:      Integer;
      FMFontName:      string;
      FMFontBold:      Boolean;
      FMFontItalic:    Boolean;
      FMFontUnderline: Boolean;
      FCaretStruct:    TGCPResults;
      FCaretStructW:   GCP_RESULTSW;
      FOutlineMetric:  TOutlineTextMetric;
      FCursorVisible:  Boolean;
      FCursorX:        Integer;
      FCursorY:        Integer;
      FCursorHeight:   Integer;
      FCursorSlope:    Integer;

      function  GetLine ( Y: Integer ): PRGBColor;
      procedure GetOutlineMetric;
      procedure SetCursorVisible ( Value: Boolean );
      procedure BuildHistogram ( out Histogram: TViewHistogram;  Shift: Byte );

    public
      constructor Create;  override;
        {  Creates a zero-sized bitmap  }
      constructor CreateSized ( AWidth, AHeight: Integer );
        {  Creates and resizes bitmap  }
      procedure   Sweep;  virtual;
        {  Resizes bitmap to (0,0) to temporary free the memory  }
      function    Sweeped: Boolean;
        {  Verifies whether either of the bitmap dimensions is zero  }
      procedure   Resize ( AWidth, AHeight: Integer );  virtual;
        {  Resizes the bitmap, recalculates scanline addr cache  }
      procedure   Clear ( Color: TRGBColor );  virtual;
        {  Fills the bitmap with given value  }
      procedure   DrawBlock ( X, Y, AWidth, AHeight: Integer;  Color: TRGBColor );
        {  Fills the rectangular region with given value  }
      procedure   DrawGlass ( X, Y, AWidth, AHeight: Integer;  Color: TRGBColor;  LeftSlope: Integer = 0;  RightSlope: Integer = 0 );
        {  Covers specified rectangle with color glass, shifting 1 px to the right after each Slope lines from bottom (if Slope <> 0)  }
      procedure   PutPixel ( X, Y: Integer;  Color: TRGBColor );
        {  Sets the pixel in a bitmap into a given value  }
      function    GetPixel ( X, Y: Integer ): TRGBColor;
        {  Returns the pixel color or (0,0,0,0) if coords are out of range }
      property    LinePtr[ Y: Integer ]: PRGBColor  read GetLine;
        {  Returns the address of a line Y, nil if Y is out of range  }
      property    Pixels [ X, Y: Integer ]: TRGBColor  read GetPixel  write PutPixel;
        { Interface to PutPixel and GetPixel }
      function    DifferentPixel ( Y: Integer;  Color: TRGBColor ): Integer;
        {  Returns X of first pixel in line Y that has a color different from given Color, or -1 if all the line is filled with given Color }
      procedure   DrawHLine ( X, Y, Length: Integer;  Color: TRGBColor );
        {  Draws a horizontal line occupying l pixels including and to the right of point (X,Y), filling drawn pixels with value c  }
      procedure   DrawVLine ( X, Y, Length: Integer;  Color: TRGBColor );
        {  Draws a vertical line occupying l pixels including and down to the point (X,Y), filling drawn pixels with value c  }
      procedure   DrawStripeHLine ( X, Y, Length, Pitch: Integer;  Color: TRGBColor );
        {  Draws a horizontal striped line occupying Length pixels including and right to the point (X,Y) with stripe Pitch  }
      procedure   DrawStripeVLine ( X, Y, Length, Pitch: Integer;  Color: TRGBColor );
        {  Draws a vertical striped line occupying Length pixels including and down to the point (X,Y) with stripe Pitch  }
      procedure   DrawFrame ( X1, Y1, Width, Height: Integer;  Color: TRGBColor );
        {  Draws a one-pixel wide rect frame by given coords  }
      procedure   DrawFrame3D ( X1, Y1, Width, Height: Integer;  LeftTopColor, RightBottomColor: TRGBColor );
        {  Draws a one-pixel wide rect frame by given coords, colored with   }
      procedure   DrawLine ( X1, Y1, X2, Y2: Integer;  Color: TRGBColor );
        {  Draws an omni-directional line going from (x1,y1) to (x2,y2) with value c  }
      procedure   StretchFrom( Source: TView;  SourceX, SourceY, Scale: Integer;  UseManualStretch: Boolean = False );
        {  Uses either StretchBlt or pascal-coded algorithm for stretching with integral zoom }
      procedure   SetFont ( FontSize: Integer;  FontName: string;  FontCharSet: TFontCharSet;  Bold, Italic, Underline: Boolean;  FontColor: TRGBColor;  FontQuality: Byte = DEFAULT_QUALITY );
        {  Makes current font settings; avoids duplicate settings  }
      procedure   SetFontColor ( FontColor: TRGBColor );
        {  Sets only font color like SetFont does  }
      procedure   Print ( X, Y: Integer;  const Text: string );
        {  Prints Text at (X, Y) using current font and transparent background  }
      procedure   PrintW ( X, Y: Integer;  const Text: WideString );
        {  Prints Text at (X, Y) using current font and transparent background  }
      function    GetCaretArray ( const Text: string ): TCaretArray;
        {  Returns an array [0..Length(Text)-1], containing relative XCoords for caret position before each char in Text (first is 0)  }
      function    GetCaretArrayW ( const Text: WideString ): TCaretArray;
        {  Returns an array [0..Length(Text)-1], containing relative XCoords for caret position before each char in Text (first is 0)  }
      function    GetTextWidth ( const Text: string ): Integer;
        {  Returns the width in pixels of the string to be printed  }
      function    GetTextWidthW ( const Text: WideString ): Integer;
        {  Returns the width in pixels of the string to be printed  }
      property    FontLineHeight: Integer  read FFontLineHeight;
        {  Returns full line height in px for current font  }
      function    FontAscent: Integer;
        {  Height above baseline of current font  }
      function    FontScriptSize: Integer;
        {  Recommended size for sub/superscript for current font  }
      function    FontSubOffset: Integer;
        {  Recommended baseline offset for subscript for current font  }
      function    FontSuperOffset: Integer;
        {  Recommended baseline offset for superscript for current font  }
      function    FontUnderlineOffset: Integer;
        {  Position of underlining  }
      function    FontUnderlineHeight: Integer;
        {  Thickness of underlining  }
      procedure   LocateCursor ( X, Y, AHeight: Integer;  Slope: Integer = 0 );
        {  Slope means the same as in DrawGlass  }
      property    CursorVisible: Boolean  read FCursorVisible  write SetCursorVisible;
        {  Hides and shows cursor  }
      procedure   BuildYHistogram( out Histogram: TViewHistogram );
        {  Builds a frequency histogram for Y channel in YCC representation  }
      procedure   BuildRHistogram( out Histogram: TViewHistogram );
        {  Builds a frequency histogram for Red channel  }
      procedure   BuildGHistogram( out Histogram: TViewHistogram );
        {  Builds a frequency histogram for Green channel  }
      procedure   BuildBHistogram( out Histogram: TViewHistogram );
        {  Builds a frequency histogram for Blue channel  }
    end;



implementation


  uses
    Math;


    
function GetCharacterPlacementW; external gdi32 name 'GetCharacterPlacementW';



  const
    UnitName = 'Views';



  function RGBColor ( R, G, B: Byte;  Z: Byte = 0 ): TRGBColor;
  begin
    Result.R := R;  Result.G := G;  Result.B := B;  Result.Z := Z;
  end;



  function RGBColorAvg ( ColorA, ColorB: TRGBColor ): TRGBColor;
  begin
    Result.R := (ColorA.R + ColorB.R) shr 1;
    Result.G := (ColorA.G + ColorB.G) shr 1;
    Result.B := (ColorA.B + ColorB.B) shr 1;
  end;



  function TRGBColorToTColor ( RGBColor: TRGBColor ): TColor;
  begin
    Result := RGBColor.B shl 16 + RGBColor.G shl 8 + RGBColor.R;
  end;



  function TColorToTRGBColor ( Color: TColor ): TRGBColor;
  var
    LColor: Longint;
  begin
    LColor := ColorToRGB (Color);
    Result.R := LColor and $FF;
    Result.G := (LColor shr 8) and $FF;
    Result.B := (LColor shr 16) and $FF;
    Result.Z := 0;
  end;



  // NOTE:
  {
    YCC implemented according to TIFF 6.0 specification, June 3, 1992, p.91.
    The following computational technique is used here for integer divisions:
    Div rounds towards zero, and we need towards -INF, so we temporary increase
    the number to become positive before applying bitwise shift, then restore.
  }

  const
    LumaRed   =  77; // 299
    LumaGreen = 150; // 587
    LumaBlue  =  29; // 114
    LumaSum   = 256; // 1000 // LumaSum = LumaRed + LumaGreen + LumaBlue.

    CoeffRed    =  1465;
    DegreeRed   =    11;

    CoeffGreen  =   437;
    DegreeGreen =    16;

    CoeffBlue   =  1155;
    DegreeBlue  =    11;

    CoeffTop    =  2048; // Power of 2 for temporary increasing to make positive before bitwise shift.
    DegreeSum   =     8;



  function TRGBColorToTYCCColor ( RGBColor: TRGBColor ): TYCCColor;
  var
    B, R: Integer;
  begin
    Result.Y := ( LumaRed * RGBColor.R + LumaGreen * RGBColor.G + LumaBlue * RGBColor.B ) shr DegreeSum;
    B := ( ( CoeffBlue * (RGBColor.B - Result.Y) ) + CoeffTop*256 ) shr DegreeBlue - (CoeffTop*256) shr DegreeBlue;
    R := ( ( CoeffRed  * (RGBColor.R - Result.Y) ) + CoeffTop*256 ) shr DegreeRed  - (CoeffTop*256) shr DegreeRed;

    if B < -128 then
      Result.B := -128
    else if B > 127 then
      Result.B := 127
    else
      Result.B := B;

    if R < -128 then
      Result.R := -128
    else if R > 127 then
      Result.R := 127
    else
      Result.R := R;
  end;



  function TRGBColorToY ( RGBColor: TRGBColor ): Byte;
  begin
    Result := ( LumaRed * RGBColor.R + LumaGreen * RGBColor.G + LumaBlue * RGBColor.B ) shr DegreeSum;
  end;



  function TYCCColorToTRGBColor ( YCCColor: TYCCColor ): TRGBColor;
  var
    R, G, B: Integer;
  begin
    R := ( 2 * YCCColor.R * (LumaSum - LumaRed ) + YCCColor.Y * LumaSum ) shr DegreeSum;
    B := ( 2 * YCCColor.B * (LumaSum - LumaBlue) + YCCColor.Y * LumaSum ) shr DegreeSum;
    G := ( CoeffGreen * ( YCCColor.Y * LumaSum - B * LumaBlue - R * LumaRed ) + CoeffTop*2*65536 ) shr DegreeGreen -
         (CoeffTop*2*65536) shr DegreeGreen;

    if R < 0 then
      Result.R := 0
    else if R > 255 then
      Result.R := 255
    else
      Result.R := R;

    if B < 0 then
      Result.B := B
    else if B > 255 then
      Result.B := 255
    else
      Result.B := B;

    if G < 0 then
      Result.G := 0
    else if G > 255 then
      Result.G := 255
    else
      Result.G := G;
  end;



  constructor TView.Create;
  begin
    CreateSized (0, 0);
  end;



  constructor TView.CreateSized ( AWidth, AHeight: Integer );
  begin
    inherited Create;
    HandleType     := bmDIB;
    PixelFormat    := pf32bit;
    Transparent    := False;
    FFontBold      := False;
    FFontItalic    := False;
    FFontUnderline := False;
    FFontColor     := TrueBlack;
    FFontSize      := 15;
    FFontName      := 'Times New Roman';
    FFontCharSet   := DEFAULT_CHARSET;
    FMFontName     := '';
    with Canvas.Font do
    begin
      Style := [];
      Color := 0;
      Height := -FFontSize;
      Name := FFontName;
      CharSet := DEFAULT_CHARSET;
    end;
    FFontLineHeight := Canvas.TextHeight (' ');
    with FCaretStruct do
    begin
      lStructSize := sizeof(FCaretStruct);
      lpOutString := nil;
      lpOrder     := nil;
      lpDx        := nil;
      lpClass     := nil;
      lpGlyphs    := nil;
    end;
    with FCaretStructW do
    begin
      lStructSize := sizeof(FCaretStructW);
      lpOutString := nil;
      lpOrder     := nil;
      lpDx        := nil;
      lpClass     := nil;
      lpGlyphs    := nil;
    end;
    Resize(AWidth, AHeight);
  end;



  procedure TView.Resize ( AWidth, AHeight: Integer );
  begin
    Height := AHeight;
    Width := AWidth;
    SetLength (FLine, AHeight);
    for AHeight := 0 to AHeight-1 do FLine[AHeight] := ScanLine[AHeight];
  end;



  procedure TView.Sweep;
  begin
    Height := 0;
    Width := 0;
    SetLength (FLine, 0);
  end;



  function TView.Sweeped: Boolean;
  begin
    Sweeped := (Height = 0) or (Width = 0);
  end;



  procedure TView.Clear ( Color: TRGBColor );
  var
    y, w: Integer;
    p: Pointer;
  begin
    FCursorVisible := False;
    w := Width;
    if w = 0 then Exit;
    for y := 0 to Height-1 do
    begin
      p := FLine[y];
      asm
        push edi
        mov  edi, p
        mov  eax, Color.c
        mov  ecx, w
        rep  stosd
        pop  edi
      end;
    end;
  end;



  procedure TView.DrawBlock ( X, Y, AWidth, AHeight: Integer;  Color: TRGBColor );
  var
    p: Pointer;
  begin
    if (X + AWidth <= 0 ) or (X >= Width ) or (Y + AHeight <= 0) or (Y >= Height) or (AHeight <= 0) or (AWidth <= 0) then Exit;
    if X < 0 then
    begin
      AWidth := AWidth + X;
      X := 0;
    end;
    if X + AWidth > Width then AWidth := Width - X;
    if Y < 0 then
    begin
      AHeight := AHeight + Y;
      Y := 0;
    end;
    if Y + AHeight > Height then AHeight := Height - Y;
    for Y := Y to Y + AHeight - 1 do
    begin
      p := FLine[Y] + X shl 2;
      asm
        push edi
        mov  edi, p
        mov  eax, Color.c
        mov  ecx, AWidth
        rep  stosd
        pop  edi
      end;
    end;
  end;



  procedure TView.DrawGlass ( X, Y, AWidth, AHeight: Integer;  Color: TRGBColor;  LeftSlope: Integer = 0;  RightSlope: Integer = 0 );
    procedure DrawGlassBlock ( X, Y, AWidth, AHeight: Integer;  Color: TRGBColor );
    var
      p: Pointer;
    begin
      if (X + AWidth <= 0 ) or (X >= Width ) or (Y + AHeight <= 0) or (Y >= Height) or (AHeight <= 0) or (AWidth <= 0) then Exit;
      if X < 0 then
      begin
        inc(AWidth, X);
        X := 0;
      end;
      if X + AWidth > Width then AWidth := Width - X;
      if Y < 0 then
      begin
        inc(AHeight, Y);
        Y := 0;
      end;
      if Y + AHeight > Height then AHeight := Height - Y;
      for Y := Y to Y + AHeight - 1 do
      begin
        p := FLine[Y] + X shl 2;
        asm
          push edi
          push ebx
          mov  edi, p
          mov  eax, Color.c
          and  eax, $FEFEFEFE
          shr  eax, 1
          mov  ecx, AWidth
        @Loop:
          mov  ebx, [edi]
          and  ebx, $FEFEFEFE
          shr  ebx, 1
          add  ebx, eax
          mov  [edi], ebx
          add  edi, 4
          dec  ecx
          jnz  @Loop
          pop  ebx
          pop  edi
        end;
      end;
    end;

    procedure DrawGlassLine ( X, Y, Length: Integer;  Color: TRGBColor );
    var
      p: Pointer;
    begin
      if (X + Length <= 0 ) or (X >= Width ) or (Y < 0) or (Y >= Height) then Exit;
      if X < 0 then
      begin
        inc(Length, X);
        X := 0;
      end;
      if X + Length > Width then Length := Width - X;
      p := FLine[Y] + X shl 2;
      asm
        push edi
        push ebx
        mov  edi, p
        mov  eax, Color.c
        and  eax, $FEFEFEFE
        shr  eax, 1
        mov  ecx, Length
      @Loop:
        mov  ebx, [edi]
        and  ebx, $FEFEFEFE
        shr  ebx, 1
        add  ebx, eax
        mov  [edi], ebx
        add  edi, 4
        dec  ecx
        jnz  @Loop
        pop  ebx
        pop  edi
      end;
    end;
    
  var
    LineX, LineY, LineWidth: Integer;
  begin
    if LeftSlope = 0 then LeftSlope := MaxInt;
    if RightSlope = 0 then RightSlope := MaxInt;
    if (LeftSlope >= AHeight) and (RightSlope >= AHeight) then
      DrawGlassBlock (X, Y, AWidth, AHeight, Color)
    else
      for LineY := Y + AHeight - 1 downto Y do
      begin
        LineX := X + ((Y+AHeight-1)-LineY) div LeftSlope;
        LineWidth := AWidth + X + ((Y+AHeight-1)-LineY) div RightSlope - LineX;
        if LineWidth <= 0 then LineWidth := 1;
        DrawGlassLine (LineX, LineY, LineWidth, Color);
      end;
  end;



  procedure TView.PutPixel ( X, Y: Integer;  Color: TRGBColor );
  begin
    if (LongWord(X) >= LongWord(Width)) or (LongWord(Y) >= LongWord(Height)) then Exit;
    PLongWord(FLine[Y] + X shl 2)^ := Color.c;
  end;



  function TView.GetPixel ( X, Y: Integer ): TRGBColor;
  begin
    Result := TrueBlack;
    if (LongWord(X) >= LongWord(Width)) or (LongWord(Y) >= LongWord(Height)) then Exit;
    Result := TColorToTRGBColor (Canvas.Pixels[X, Y]);
  end;



  function TView.DifferentPixel ( Y: Integer;  Color: TRGBColor ): Integer;
  var
    X: Integer;
  begin
    Result := -1;
    for X := 0 to Width-1 do
      if Pixels[X, Y].C <> Color.C then
      begin
        Result := X;
        Exit;
      end;
  end;



  procedure TView.DrawHLine ( X, Y, Length: Integer;  Color: TRGBColor );
  var
    p: Pointer;
  begin
    if (LongWord(Y) >= LongWord(Height)) or (Length <= 0) or (X + Length <= 0) or (X >= Width) then Exit;
    if X < 0 then
    begin
      Length := Length + X;
      X := 0;
    end;
    if X + Length > Width then Length := Width - X;
    p := FLine[Y] + X shl 2;
    asm
      push edi
      mov  edi, p
      mov  eax, Color.c
      mov  ecx, Length
      rep  stosd
      pop  edi
    end;
  end;



  procedure TView.DrawVLine ( X, Y, Length: Integer;  Color: TRGBColor );
  begin
    if (LongWord(X) >= LongWord(Width)) or (Length <= 0) or (Y + Length <= 0) or (Y >= Height) then Exit;
    if Y < 0 then
    begin
      Length := Length + Y;
      Y := 0;
    end;
    if Y + Length > Height then Length := Height - Y;
    for Y := Y to Y + Length - 1 do PLongWord(FLine[Y] + X shl 2)^ := Color.c;
  end;



  procedure TView.DrawStripeHLine ( X, Y, Length, Pitch: Integer;  Color: TRGBColor );
  var
    p: Pointer;
  begin
    if (LongWord(Y) >= LongWord(Height)) or (Length <= 0) or (X + Length <= 0) or (X >= Width) then Exit;
    if X < 0 then
    begin
      Length := Length + X;
      X := 0;
    end;
    if X + Length > Width then Length := Width - X;
    if Pitch = 0 then
    begin  // DrawHLine
      p := FLine[Y] + X shl 2;
      asm
        push edi
        mov  edi, p
        mov  eax, Color.c
        mov  ecx, Length
        rep  stosd
        pop  edi
      end;
    end
    else
      for X := X to X + Length - 1 do
        if Odd(X div Pitch) then PLongWord(FLine[Y] + X shl 2)^ := Color.c;
  end;



  procedure TView.DrawStripeVLine ( X, Y, Length, Pitch: Integer;  Color: TRGBColor );
  begin
    if (LongWord(X) >= LongWord(Width)) or (Length <= 0) or (Y + Length <= 0) or (Y >= Height) then Exit;
    if Y < 0 then
    begin
      Length := Length + Y;
      Y := 0;
    end;
    if Y + Length > Height then Length := Height - Y;
    if Pitch = 0 then
      for Y := Y to Y + Length - 1 do
        PLongWord(FLine[Y] + X shl 2)^ := Color.c
    else
      for Y := Y to Y + Length - 1 do
        if Odd(Y div Pitch) then PLongWord(FLine[Y] + X shl 2)^ := Color.c;
  end;



  procedure TView.DrawFrame ( X1, Y1, Width, Height: Integer;  Color: TRGBColor );
  begin
    if (Width <= 0) or (Height <= 0) then Exit;
    DrawHLine (X1, Y1, Width-1, Color);
    DrawVLine (X1, Y1+1, Height-2, Color);
    DrawHLine (X1, Y1+Height-1, Width, Color);
    DrawVLine (X1+Width-1, Y1, Height-1, Color);
  end;



  procedure TView.DrawFrame3D ( X1, Y1, Width, Height: Integer;  LeftTopColor, RightBottomColor: TRGBColor );
  begin
    if (Width <= 0) or (Height <= 0) then Exit;
    DrawHLine (X1, Y1, Width-1, LeftTopColor);
    DrawVLine (X1, Y1+1, Height-2, LeftTopColor);
    DrawHLine (X1, Y1+Height-1, Width, RightBottomColor);
    DrawVLine (X1+Width-1, Y1, Height-1, RightBottomColor);
  end;


  
  procedure TView.DrawLine ( X1, Y1, X2, Y2: Integer;  Color: TRGBColor );
  var
    x, y, dx, dy, s: Integer;
  begin
    if abs(y2-y1) <= abs(x2-x1) then
    begin { Horizontal }
      if x1 = x2 then begin PutPixel(X1, Y1, Color); exit end;
      if x1 > x2 then begin x := x1;  x1 := x2;  x2 := x;  y := y1;  y1 := y2;  y2 := y end;
      if y2 > y1 then
      begin
        y := y1;  s := x2-x1;  dy:=(y2-y1) shl 1;  dx:=(x2-x1) shl 1;
        for x := x1 to x2-1 do
        begin
          PutPixel (x, y, Color);
          s := s + dy;  if s >= dx then  begin  inc (y);  s := s - dx  end;
        end;
        PutPixel (x2, y, Color);
      end
      else
      begin
        y := y1;  s := x2-x1;  dy:=(y1-y2) shl 1;  dx:=(x2-x1) shl 1;
        for x := x1 to x2-1 do
        begin
          PutPixel (x, y, Color);
          s := s + dy;  if s >= dx then  begin  dec (y);  s := s - dx  end;
        end;
        PutPixel (x2, y, Color);
      end;
    end
    else
    begin { Vertical }
      if y1 > y2 then begin x := x1;  x1 := x2;  x2 := x;  y := y1;  y1 := y2;  y2 := y end;
      if x2 > x1 then
      begin
        x := x1;  s := y2-y1;  dy:=(y2-y1) shl 1;  dx:=(x2-x1) shl 1;
        for y:=y1 to y2-1 do
        begin
          PutPixel (x, y, Color);
          s := s + dx;  if s >= dy then  begin  inc (x);  s := s - dy  end;
        end;
        PutPixel (x, y2, Color);
      end
      else
      begin
        x := x1;  s := y2-y1;  dy:=(y2-y1) shl 1;  dx:=(x1-x2) shl 1;
        for y:=y1 to y2-1 do
        begin
          PutPixel (x, y, Color);
          s := s + dx;  if s >= dy then  begin  dec (x);  s := s - dy  end;
        end;
        PutPixel (x, y2, Color);
      end;
    end;
  end;



  procedure TView.StretchFrom( Source: TView;  SourceX, SourceY, Scale: Integer;  UseManualStretch: Boolean = False );
  var
    I: Integer;
    X, Y: Integer;
    DestY: Integer;
    SourceP, DestP, DestStartP: PRGBColor;
    SourceWidth, SourceHeight: Integer;
    DestLineSize: Integer;

  begin
    Assert( (Width mod Scale = 0) and (Height mod Scale = 0) );

    SourceWidth := Width div Scale;
    SourceHeight := Height div Scale;

    if not UseManualStretch then
    begin
      StretchBlt( Canvas.Handle, 0, 0, Width, Height,
                  Source.Canvas.Handle, SourceX, SourceY, SourceWidth, SourceHeight, SRCCOPY );
      Exit;
    end;

    DestLineSize := Width * SizeOf( TRGBColor );

    DestY := 0;
    for Y := SourceY to SourceY + SourceHeight - 1 do
    begin
      SourceP := Source.LinePtr[Y];
      Inc( SourceP, SourceX );

      DestStartP := LinePtr[DestY];

      DestP := DestStartP;

      for X := 0 to SourceWidth-1 do
      begin
        for I := 0 to Scale-1 do
        begin
          DestP^ := SourceP^;
          Inc( DestP );
        end;
        Inc( SourceP );
      end;

      Inc( DestY );
      DestP := LinePtr[DestY];

      for I := 0 to (Scale - 2)-1 do
      begin
        Move( DestStartP^, DestP^, DestLineSize );
        Inc( DestY );
        DestP := LinePtr[DestY];
      end;

      Move( DestStartP^, DestP^, DestLineSize );
      Inc( DestY );
    end;
  end;



  procedure TView.SetFont ( FontSize: Integer;  FontName: string;  FontCharSet: TFontCharSet;  Bold, Italic, Underline: Boolean;  FontColor: TRGBColor;  FontQuality: Byte = DEFAULT_QUALITY );
  var
    HeightChanged: Boolean;
    LogFont: TLogFont;
    TempFont: TFont;
  begin
    HeightChanged := False;
    with Canvas.Font do
    begin
      if FFontSize <> FontSize then
      begin
        FFontSize := FontSize;
        Height := FontSize;
        HeightChanged := True;
      end;
      if Pos(' CYR', AnsiUpperCase(FontName)) = (Length(FontName) - 3) then
        FontName := Copy (FontName, 1, Length(FontName)-4);
      if FFontName <> FontName then
      begin
        FFontName := FontName;
        Name      := FontName;
        HeightChanged   := True;
      end;
      if FFontCharSet <> FontCharSet then
      begin
        FFontCharSet := FontCharSet;
        CharSet := FontCharSet;
        HeightChanged := True;
      end;
      if FFontBold <> Bold then
      begin
        FFontBold := Bold;
        if Bold then Style := Style + [fsBold] else Style := Style - [fsBold];
        HeightChanged := True;
      end;
      if FFontItalic <> Italic then
      begin
        FFontItalic := Italic;
        if Italic then Style := Style + [fsItalic] else Style := Style - [fsItalic];
        HeightChanged := True;
      end;
      if FFontUnderline <> Underline then
      begin
        FFontUnderline := Underline;
        if Underline then Style := Style + [fsUnderline] else Style := Style - [fsUnderline];
        HeightChanged := True;
      end;
      if FFontColor.c <> FontColor.c then
      begin
        FFontColor := FontColor;
        Color := TRGBColorToTColor (FontColor);
      end;
      if FFontQuality <> FontQuality then
      begin
        FFontQuality := FontQuality;

        TempFont:= TFont.Create;
        try
          TempFont.Assign(Canvas.Font);
          GetObject(TempFont.Handle, sizeof(LogFont), @LogFont);
          LogFont.lfQuality := FFontQuality;
          TempFont.Handle:= CreateFontIndirect(LogFont);
          Canvas.Font.Assign(TempFont);
        finally
          TempFont.Free
        end;
      end;
    end;
    if HeightChanged then
      FFontLineHeight := Canvas.TextHeight (' ');
  end;



  procedure TView.SetFontColor ( FontColor: TRGBColor );
  begin
    with Canvas.Font do
      if FFontColor.c <> FontColor.c then
      begin
        FFontColor := FontColor;
        Color := TRGBColorToTColor (FontColor);
      end;
  end;



  procedure TView.Print ( X, Y: Integer;  const Text: string );
  begin
    SetBkMode (Canvas.Handle, 1);
    Windows.TextOut (Canvas.Handle, X, Y, PChar(Text), Length(Text));
  end;



  procedure TView.PrintW ( X, Y: Integer;  const Text: WideString);
  begin
    SetBkMode (Canvas.Handle, 1);
    Windows.TextOutW (Canvas.Handle, X, Y, PWideChar(Text), Length(Text));
  end;



  function TView.GetCaretArray ( const Text: string ): TCaretArray;
  begin
    SetLength (Result, Length(Text));
    FCaretStruct.lpCaretPos := @Result[0];
    FCaretStruct.nGlyphs := Length(Text);
    if GetCharacterPlacement (Canvas.Handle, PAnsiChar(Text), Length(Text), 0, FCaretStruct, 0{GCP_USEKERNING} ) = 0 then
      raise Exception.Create ( 'InternalError: [' +  UnitName + ']  TView.GetCaretArray: Win32 API call GetCharacterPlacement failed.' );
  end;



  function TView.GetCaretArrayW ( const Text: WideString ): TCaretArray;
  begin
    SetLength (Result, Length(Text));
    FCaretStructW.lpCaretPos := @Result[0];
    FCaretStructW.nGlyphs := Length(Text);
    if GetCharacterPlacementW (Canvas.Handle, PWideChar(Text), Length(Text), 0, @FCaretStructW, 0{GCP_USEKERNING} ) = 0 then
    begin
      if Length(Text) = 2 then
      begin
        raise Exception.Create ( 'InternalError: [' +  UnitName +
          ']  TView.GetCaretArrayW: Win32 API call GetCharacterPlacementW failed: '#13#10 +
          'Text[1] = ' + Format('#x%x', [Ord(Text[1])]) + ', Text[2] = ' +
          Format('#x%x', [Ord(Text[2])]) + '.');
      end
      else
      begin
        raise Exception.Create ( 'InternalError: [' +  UnitName +
          ']  TView.GetCaretArrayW: Win32 API call GetCharacterPlacementW failed: '#13#10 +
          'Length(Text) = ' + IntToStr(Length(Text)));
      end;
    end;
  end;



  function TView.GetTextWidth ( const Text: string ): Integer;
  var
    CaretArray: TCaretArray;
  begin
    CaretArray := GetCaretArray(Text + 'X');
    Result := CaretArray[High(CaretArray)];
  end;



  function TView.GetTextWidthW ( const Text: WideString ): Integer;
  var
    CaretArray: TCaretArray;
  begin
    CaretArray := GetCaretArrayW(Text + 'X');
    Result := CaretArray[High(CaretArray)];
  end;



  function TView.GetLine ( Y: Integer ): PRGBColor;
  begin
    if (Y < 0) or (Y >= Height) then
    begin
      Result := nil;
      Exit;
    end;
    Result := PRGBColor( FLine[Y] );
  end;



  procedure TView.GetOutlineMetric;
  begin
    if (FMFontName = FFontName) and (FMFontSize = FFontSize) and
       (FMFontBold = FFontBold) and (FMFontItalic = FFontItalic) and (FMFontUnderline = FFontUnderline) then Exit;
    FMFontName      := FFontName;
    FMFontSize      := FFontSize;
    FMFontBold      := FFontBold;
    FMFontItalic    := FFontItalic;
    FMFontUnderline := FFontUnderline;
    GetOutlineTextMetrics (Canvas.Handle, sizeof(FOutlineMetric), @FOutlineMetric);
    if UpperCase(FFontName) = 'SYMBOL' then
      FOutlineMetric.otmTextMetrics.tmAscent := Round(0.8 * FFontLineHeight);
  end;


  function TView.FontAscent: Integer;
  begin
    GetOutlineMetric;
    Result := FOutlineMetric.otmTextMetrics.tmAscent;
  end;



  function TView.FontScriptSize: Integer;
  begin
    GetOutlineMetric;
    Result := FOutlineMetric.otmptSubscriptSize.Y;
  end;



  function TView.FontSubOffset: Integer;
  begin
    GetOutlineMetric;
    Result := FOutlineMetric.otmptSubscriptOffset.Y;
  end;



  function TView.FontSuperOffset: Integer;
  begin
    GetOutlineMetric;
    Result := FOutlineMetric.otmptSuperscriptOffset.Y;
  end;



  function TView.FontUnderlineOffset: Integer;
  begin
    GetOutlineMetric;
    Result := FOutlineMetric.otmsUnderscorePosition;
  end;



  function TView.FontUnderlineHeight: Integer;
  begin
    GetOutlineMetric;
    Result := FOutlineMetric.otmsUnderscoreSize;
  end;



  procedure TView.LocateCursor ( X, Y, AHeight: Integer;  Slope: Integer = 0 );
  begin
    if FCursorVisible then
    begin
      SetCursorVisible (False);
      FCursorX := X;
      FCursorY := Y;
      FCursorHeight := AHeight;
      if Slope = 0 then Slope := MaxInt;
      FCursorSlope := Slope;
      SetCursorVisible (True);
    end
    else
    begin
      FCursorX := X;
      FCursorY := Y;
      FCursorHeight := AHeight;
      if Slope = 0 then Slope := MaxInt;
      FCursorSlope := Slope;
    end;
  end;



  procedure TView.SetCursorVisible ( Value: Boolean );
    procedure DrawCursor ( X, Y, AHeight: Integer );
    var
      p: Pointer;
    begin
      if X = -1 then inc(X);
      if (Longword(X) >= Longword(Width)) or (AHeight <= 0) or (Y + AHeight <= 0) or (Y >= Height) then Exit;
      if Y < 0 then
      begin
        AHeight := AHeight + Y;
        Y := 0;
      end;
      if Y + AHeight > Height then AHeight := Height - Y;
      if (X >= 0) and (X+2 < Width) then
      begin
        for Y := Y to Y + AHeight - 1 do
        begin
          p := FLine[Y] + X shl 2;
          asm
            push edi
            mov edi, p
            mov eax, $FFFFFFFF
            xor [edi], eax
            add edi, 4
            xor [edi], eax
            pop edi
          end;
        end;
        exit;
      end;
      if X = -1 then X := 0;
      for Y := Y to Y + AHeight - 1 do
      begin
        p := FLine[Y] + X shl 2;
        asm
          push edi
          mov edi, p
          mov eax, $FFFFFFFF
          xor [edi], eax
          pop edi
        end;
      end;
    end;
  var
    i: Integer;
  begin
    if FCursorVisible = Value then Exit;
    FCursorVisible := Value;
    if FCursorSlope >= FCursorHeight then
      DrawCursor (FCursorX, FCursorY, FCursorHeight)
    else
    begin
      for i := 1 to FCursorHeight div FCursorSlope do
        DrawCursor (FCursorX+i-1, FCursorY+FCursorHeight-FCursorSlope*i, FCursorSlope);
      DrawCursor (FCursorX+FCursorHeight div FCursorSlope, FCursorY, FCursorHeight mod FCursorSlope);
    end;
  end;



  procedure TView.BuildHistogram ( out Histogram: TViewHistogram;  Shift: Byte );
  var
    X, Y: Integer;
    P: PChar;
  begin
    FillChar( Histogram[0], SizeOf(Histogram), 0 );

    for Y := 0 to Height-1 do
    begin
      P := FLine[Y];
      for X := 0 to Width-1 do
        Inc( Histogram[ Byte( PLongword(P + X shl 2)^ shr Shift ) ] );
    end;
  end;



  procedure TView.BuildYHistogram ( out Histogram: TViewHistogram );
  var
    X, Y: Integer;
    P: PChar;
  begin
    FillChar( Histogram[0], SizeOf(Histogram), 0 );

    for Y := 0 to Height-1 do
    begin
      P := FLine[Y];
      for X := 0 to Width-1 do
        Inc( Histogram[ TRGBColorToY( PRGBColor(P + X shl 2)^ ) ] );
    end;
  end;



  procedure TView.BuildRHistogram ( out Histogram: TViewHistogram );
  begin
    BuildHistogram( Histogram, 16 );
  end;



  procedure TView.BuildGHistogram ( out Histogram: TViewHistogram );
  begin
    BuildHistogram( Histogram, 8 );
  end;



  procedure TView.BuildBHistogram ( out Histogram: TViewHistogram );
  begin
    BuildHistogram( Histogram, 0 );
  end;



  function ViewHistogramMax ( const Histogram: TViewHistogram ): Integer;

  var
    I: Integer;

  begin
    Result := 0;
    for I := 0 to High(Histogram) do
      if Histogram[I] > Result then
        Result := Histogram[I];
  end;



end.





