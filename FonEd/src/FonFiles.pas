unit FonFiles;

interface

uses
  SysUtils, Classes, Contnrs,
  FntFiles;

//======================================================================================================================
type
//----------------------------------------------------------------------------------------------------------------------

  TVersionNumber = record
    Major: Word;
    Minor: Word;
    Release: Word;
    Build: Word;
  end;

//----------------------------------------------------------------------------------------------------------------------

  EWrongFileFormat = class(Exception)
    {EMPTY}
  end;

//----------------------------------------------------------------------------------------------------------------------

  TFonFile = class

  private
    FModuleName: string;
    FDescription: string;

    FFileVersionNumber: TVersionNumber;
    FProductVersionNumber: TVersionNumber;

    FCompanyName: string;
    FFileDescription: string;
    FFileVersion: string;
    FInternalName: string;
    FLegalCopyright: string;
    FOriginalFileName: string;
    FProductName: string;
    FProductVersion: string;

    FLanguageCode: Word;
    FCharSetCode: Word;

    FFonts: TObjectList{of TFntFile};

    constructor Create;

    procedure ReadVersion(Stream: TStream);
    procedure SaveVersion(Stream: TStream);

  public
    constructor CreateFromFile(const FileName: string;
      out SkippedVectorFonts, SkippedUnsupportedFonts: Integer);
    destructor Destroy; override;
    procedure SaveToFile(const FileName: string);

    property ModuleName: string read FModuleName write FModuleName;
    property Description: string read FDescription write FDescription;

    property FileVersionNumber: TVersionNumber read FFileVersionNumber write FFileVersionNumber;
    property ProductVersionNumber: TVersionNumber read FProductVersionNumber write FProductVersionNumber;

    property CompanyName: string read FCompanyName write FCompanyName;
    property FileDescription: string read FFileDescription write FFileDescription;
    property FileVersion: string read FFileVersion write FFileVersion;
    property InternalName: string read FInternalName write FInternalName;
    property LegalCopyright: string read FLegalCopyright write FLegalCopyright;
    property OriginalFileName: string read FOriginalFileName write FOriginalFileName;
    property ProductName: string read FProductName write FProductName;
    property ProductVersion: string read FProductVersion write FProductVersion;

    property LanguageCode: Word read FLanguageCode write FLanguageCode;
    property CharSetCode: Word read FCharSetCode write FCharSetCode;

    property Fonts: TObjectList{of TFntFile} read FFonts;
  end;

//======================================================================================================================
implementation /////////////////////////////////////////////////////////////////////////////////////////////////////////
//----------------------------------------------------------------------------------------------------------------------

uses
  SubStreams;

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

//----------------------------------------------------------------------------------------------------------------------

procedure WriteNullTermString(Stream: TStream; const S: string);

begin
  Stream.WriteBuffer(S[1], Length(S) + {null-term}1);
end;

//----------------------------------------------------------------------------------------------------------------------

procedure SeekToAlign32(Stream: TStream);

begin
  Stream.Position := ((Stream.Position + 3) div 4) * 4;
end;

//----------------------------------------------------------------------------------------------------------------------

procedure WriteToAlign32(Stream: TStream);

var
  Buffer: array of Byte;

begin
  SetLength(Buffer, ((Stream.Position + 3) div 4) * 4 - Stream.Position);
  FillChar(Buffer[0], Length(Buffer), 0);
  Stream.WriteBuffer(Buffer[0], Length(Buffer));
end;

//----------------------------------------------------------------------------------------------------------------------

procedure WriteToAlign16Bytes(Stream: TStream);

var
  Buffer: array of Byte;

begin
  SetLength(Buffer, ((Stream.Position + 15) div 16) * 16 - Stream.Position);
  FillChar(Buffer[0], Length(Buffer), 0);
  Stream.WriteBuffer(Buffer[0], Length(Buffer));
end;

//----------------------------------------------------------------------------------------------------------------------

procedure WriteSize(Stream: TStream; SizePosition: Int64);

var
  CurPos: Int64;
  Size: Word;

begin
  CurPos := Stream.Position;
  Stream.Position := SizePosition;
  Size := CurPos - SizePosition;
  Stream.WriteBuffer(Size, 2);
  Stream.Position := CurPos;
end;

//======================================================================================================================
type
//----------------------------------------------------------------------------------------------------------------------

  TNEHeader = packed record

    {00h} NESignature: Word;
    {02h} LinkerVersion: Byte;
    {03h} LinkerRevision: Byte;
    {04h} EntryTableOfs: Word;
    {06h} EntryTableSize: Word;
    {08h} CheckSum: Longword;
    {0Ch} Flags: Word;
    {0Eh} AutoSegsCount: Word;
    {10h} HeapSize: Word;
    {12h} StackSize: Word;
    {14h} Entry_CS_IP: Longword;
    {18h} Stack_SS_SP: Longword;
    {1Ch} SegsCount: Word;
    {1Eh} ModulesCount: Word;
    {20h} NonResNameTableSize: Word;
    {22h} SegTableOfs: Word;
    {24h} ResTableOfs: Word;
    {26h} ResNameTableOfs: Word;
    {28h} ModuleTableOfs: Word;
    {2Ah} ImpNameTableOfs: Word;
    {2Ch} NonResNameTableOfs: Word;
    {2Eh} NotUsed1: Word;
    {30h} MovableEntryCount: Word;
    {32h} Alignment: Word;
    {34h} ResSegsCount: Word;
    {36h} OSId: Byte;
    {37h} ExtraFlags: Byte;
    {38h} GangLoadSecOfs: Word;
    {3Ah} GangLoadSecSize: Word;
    {3Ch} NotUsed2: Word;
    {3Eh} WindowsVersion: Word;
  end;

//----------------------------------------------------------------------------------------------------------------------

  TRes = packed record

    Ofs: Word;
    Size: Word;
    Flags: Word;
    Id: Word;
    Reserved: Longword;
  end;

//----------------------------------------------------------------------------------------------------------------------

  TFixedVersionInfo = packed record

    dwSignature: Longword; // Signature - always 0xFEEF04DB.
    dwStrucVersion: Longword; // Structure version - currently 0.
    dwFileVersionMS: Longword; // Most Significant file version dword.
    dwFileVersionLS: Longword; // Least Significant file version dword.
    dwProductVersionMS: Longword; // Most Significant product version.
    dwProductVersionLS: Longword; // Least Significant product version.
    dwFileFlagMask: Longword; // File flag mask.
    dwFileFlags: Longword; // Set of debug/retail/prerelease/...
    dwFileOS: Longword; // OS type.  Will always be Windows32 value.
    dwFileType: Longword; // Type of file (dll/exe/drv/...).
    dwFileSubtype: Longword; // File subtype.
    dwFileDateMS: Longword; // Most Significant part of date.
    dwFileDateLS: Longword; // Least Significant part of date.
  end;

//======================================================================================================================
// TFonFile
//----------------------------------------------------------------------------------------------------------------------

constructor TFonFile.Create;

begin
  FFonts := TObjectList.Create;
end;

//----------------------------------------------------------------------------------------------------------------------

destructor TFonFile.Destroy;

begin
  FFonts.Free;
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TFonFile.ReadVersion(Stream: TStream);

var
  Len: Word;
  ValueLen: Word;
  FixedInfo: TFixedVersionInfo;
  S: string;
  W: Word;
  Start: Integer;
  Size: Integer;
  Key: string;
  Value: string;

begin
  // Reading VS_VERSION_INFO:
  Stream.ReadBuffer(Len, 2);
  Stream.ReadBuffer(ValueLen, 2);
  S := ReadNullTermString(Stream);
  if S <> 'VS_VERSION_INFO' then Exit;
  Stream.ReadBuffer(FixedInfo, SizeOf(FixedInfo));
  with FixedInfo do
  begin
    if dwSignature <> $FEEF04BD then Exit;
    FFileVersionNumber.Major := dwFileVersionMS shr 16;
    FFileVersionNumber.Minor := dwFileVersionMS and $FFFF;
    FFileVersionNumber.Release := dwFileVersionLS shr 16;
    FFileVersionNumber.Build := dwFileVersionLS and $FFFF;
    FProductVersionNumber.Major := dwProductVersionMS shr 16;
    FProductVersionNumber.Minor := dwProductVersionMS and $FFFF;
    FProductVersionNumber.Release := dwProductVersionLS shr 16;
    FProductVersionNumber.Build := dwProductVersionLS and $FFFF;
  end;

  // Reading StringFileInfo:
  Stream.ReadBuffer(Len, 2);
  Stream.ReadBuffer(ValueLen, 2);
  S := ReadNullTermString(Stream);
  if S <> 'StringFileInfo' then Exit;
  SeekToAlign32(Stream);
  Start := Stream.Position;
  Stream.ReadBuffer(Len, 2);
  Size := Len;
  Stream.ReadBuffer(ValueLen, 2);
  ReadNullTermString(Stream); // Language key.
  while Stream.Position < Start + Size do
  begin
    SeekToAlign32(Stream);
    Stream.ReadBuffer(Len, 2);
    Stream.ReadBuffer(ValueLen, 2);
    Key := ReadNullTermString(Stream);
    SeekToAlign32(Stream);
    Value := Trim(ReadNullTermString(Stream));
    if Key = 'CompanyName' then
      FCompanyName := Value
    else if Key = 'FileDescription' then
      FFileDescription := Value
    else if Key = 'FileVersion' then
      FFileVersion := Value
    else if Key = 'InternalName' then
      FInternalName := Value
    else if Key = 'LegalCopyright' then
      FLegalCopyright := Value
    else if Key = 'OriginalFilename' then
      FOriginalFileName := Value
    else if Key = 'ProductName' then
      FProductName := Value
    else if Key = 'ProductVersion' then
      FProductVersion := Value;
  end;

  // Reading VarFileInfo:
  SeekToAlign32(Stream);
  Stream.ReadBuffer(Len, 2);
  Stream.ReadBuffer(ValueLen, 2);
  S := ReadNullTermString(Stream);
  if S <> 'VarFileInfo' then Exit;
  SeekToAlign32(Stream);
  Stream.ReadBuffer(Len, 2);
  Stream.ReadBuffer(ValueLen, 2);
  S := ReadNullTermString(Stream);
  if S <> 'Translation' then Exit;
  SeekToAlign32(Stream);
  Stream.ReadBuffer(W, 2);
  FLanguageCode := W;
  Stream.ReadBuffer(W, 2);
  FCharSetCode := W;
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TFonFile.SaveVersion(Stream: TStream);

  //....................................................................................................................

  procedure WriteVersionString(const Key, Value: string);

  const
    SizePlaceholder: Word = 0;

  var
    ValueSize: Word;
    SizePosition: Int64;

  begin
    SizePosition := Stream.Position;
    Stream.WriteBuffer(SizePlaceholder, 2);
    begin
      ValueSize := Length(Value) + {null-term}1;
      Stream.WriteBuffer(ValueSize, 2);
      WriteNullTermString(Stream, Key);
      WriteToAlign32(Stream);
      WriteNullTermString(Stream, Value);
    end;
    WriteSize(Stream, SizePosition);
  end;

  //....................................................................................................................

const
  SizePlaceholder: Word = 0;
  ZeroValueSize: Word = 0;
  VarFileInfo: array [0..31] of Byte =
  (
    $24, $00, $00, $00, $56, $61, $72, $46, $69, $6C, $65, $49, $6E, $66, $6F, $00,
    $14, $00, $04, $00, $54, $72, $61, $6E, $73, $6C, $61, $74, $69, $6F, $6E, $00
  );

var
  FixedVersionInfo: TFixedVersionInfo;
  TotalSizePosition: Int64;
  FixedInfoSize: Word;
  StringFileInfoSizePosition: Int64;
  StringFileInfoLangSizePosition: Int64;

begin
  with FixedVersionInfo do
  begin
    dwSignature := $FEEF04BD;
    dwStrucVersion := $10000;
    dwFileVersionMS := FFileVersionNumber.Major shl 16 + FFileVersionNumber.Minor;
    dwFileVersionLS := FFileVersionNumber.Release shl 16 + FFileVersionNumber.Build;
    dwProductVersionMS := FProductVersionNumber.Major shl 16 + FProductVersionNumber.Minor;
    dwProductVersionLS := FProductVersionNumber.Release shl 16 + FProductVersionNumber.Build;
    dwFileFlagMask := $3F;
    dwFileFlags := $02;
    dwFileOS := $10001;
    dwFileType := 4;
    dwFileSubtype := 1;
    dwFileDateMS := 0;
    dwFileDateLS := 0;
  end;

  TotalSizePosition := Stream.Position;
  Stream.WriteBuffer(SizePlaceholder, 2);
  begin
    // Writing VS_VERSION_INFO:
    FixedInfoSize := SizeOf(FixedVersionInfo);
    Stream.WriteBuffer(FixedInfoSize, 2);
    WriteNullTermString(Stream, 'VS_VERSION_INFO');
    Stream.WriteBuffer(FixedVersionInfo, SizeOf(FixedVersionInfo));

    WriteToAlign32(Stream);

    // Write StringFileInfo:
    StringFileInfoSizePosition := Stream.Position;
    Stream.WriteBuffer(SizePlaceholder, 2);
    begin
      Stream.WriteBuffer(ZeroValueSize, 2);
      WriteNullTermString(Stream, 'StringFileInfo');
      WriteToAlign32(Stream);

      // Write StringFileInfoLang:
      StringFileInfoLangSizePosition := Stream.Position;
      Stream.WriteBuffer(SizePlaceholder, 2);
      begin
        Stream.WriteBuffer(ZeroValueSize, 2);
        WriteNullTermString(Stream, Format('%.4x%.4x', [FLanguageCode, FCharSetCode]));
        WriteToAlign32(Stream);
        WriteVersionString('CompanyName', FCompanyName);
        WriteToAlign32(Stream);
        WriteVersionString('FileDescription', FFileDescription);
        WriteToAlign32(Stream);
        WriteVersionString('FileVersion', FFileVersion);
        WriteToAlign32(Stream);
        WriteVersionString('InternalName', FInternalName);
        WriteToAlign32(Stream);
        WriteVersionString('LegalCopyright', FLegalCopyright);
        WriteToAlign32(Stream);
        WriteVersionString('OriginalFilename', FOriginalFileName);
        WriteToAlign32(Stream);
        WriteVersionString('ProductName', FProductName);
        WriteToAlign32(Stream);
        WriteVersionString('ProductVersion', FProductVersion);
      end;
      WriteSize(Stream, StringFileInfoLangSizePosition);
    end;
    WriteSize(Stream, StringFileInfoSizePosition);

    WriteToAlign32(Stream);

    // Write VarFileInfo:
    Stream.WriteBuffer(VarFileInfo, Length(VarFileInfo));

    // Write Translation language and charset codes:
    Stream.WriteBuffer(FLanguageCode, 2);
    Stream.WriteBuffer(FCharsetCode, 2);
  end;
  WriteSize(Stream, TotalSizePosition);
end;

//----------------------------------------------------------------------------------------------------------------------

constructor TFonFile.CreateFromFile(const FileName: string;
  out SkippedVectorFonts, SkippedUnsupportedFonts: Integer); {raise EReadError, EWrongFileFormat}

var
  FS: TFileStream;
  W: Word;
  B: Byte;
  I: Integer;
  TypeId: Word;
  ResCount: Word;
  NotUsed: Longword;
  Res: TRes;
  NEHeaderOfs: Word;
  NEHeader: TNEHeader;
  AlignmentPw: Word;
  HaveVersion: Boolean;
  ResourceStream: TSubStream;

begin
  Create;

  FS := TFileStream.Create(FileName, fmOpenRead);
  try

    // Read 'MZ' signature:
    FS.ReadBuffer(W, 2);
    if(W <> $4D5A) and(W <> $5A4D) then
      raise EWrongFileFormat.Create('MZ signature not found.');

    // Find offset for NE header:
    FS.Position := $18;
    FS.ReadBuffer(B, 1);
    if B < $40 then
      raise EWrongFileFormat.Create('Possibly not NE but MZ format found.');
    FS.Position := $3C;
    FS.ReadBuffer(NEHeaderOfs, 2);

    // Read 'NE' signature:
    FS.Position := NEHeaderOfs;
    FS.ReadBuffer(W, 2);
    if W <> $454E then
      raise EWrongFileFormat.Create('NE signature not found.');

    // Read NE header:
    FS.Position := NEHeaderOfs;
    FS.ReadBuffer(NEHeader, SizeOf(NEHeader));

    // Read ResTable:
    if NEHeader.ResTableOfs >= NEHeader.ResNameTableOfs then
      raise EWrongFileFormat.Create('Resource table not found.');
    FS.Position := NEHeaderOfs + NEHeader.ResTableOfs;
    FS.ReadBuffer(AlignmentPw, 2);

    HaveVersion := False;
    SkippedVectorFonts := 0;
    SkippedUnsupportedFonts := 0;
    while True do
    begin
      FS.ReadBuffer(TypeId, 2);
      if TypeId = 0 then Break;

      FS.ReadBuffer(ResCount, 2);
      FS.ReadBuffer(NotUsed, 4);
      for I := 0 to ResCount-1 do
      begin
        FS.ReadBuffer(Res, SizeOf(Res));
        ResourceStream := TSubStream.Create(FS, (1 shl AlignmentPw) * Res.Ofs, (1 shl AlignmentPw) * Res.Size);
        try
          case TypeId of

             8 + $8000 {RT_FONT}:
              try
                Fonts.Add(TFntFile.CreateFromStream(ResourceStream));
              except
                on EFontIsVector do
                  Inc(SkippedVectorFonts);
                on EUnsupportedFontVersion do
                  Inc(SkippedUnsupportedFonts);
                else
                  raise;
              end;

            16 + $8000 {RT_VERSION}:
              if not HaveVersion then
              begin
                ReadVersion(ResourceStream);
                HaveVersion := True;
              end
              else
              begin
                {NOP}; // Duplicate version resources are ignored here.
              end;
          end;
        finally
          ResourceStream.Free;
        end;
      end;
    end;

    // Read FModuleName from first entry of ResNameTable:
    if NEHeader.ResNameTableOfs < NEHeader.ModuleTableOfs then
    begin
      FS.Position := NEHeaderOfs + NEHeader.ResNameTableOfs;
      FS.ReadBuffer(B, 1);
      if B <> 0 then
      begin
        SetLength(FModuleName, B);
        FS.ReadBuffer(FModuleName[1], B);
      end;
    end;

    // Read FDescription from first entry of NonResNameTable:
    if NEHeader.NonResNameTableSize > 0 then
    begin
      FS.Position := NEHeader.NonResNameTableOfs;
      FS.ReadBuffer(B, 1);
      if B <> 0 then
      begin
        SetLength(FDescription, B);
        FS.ReadBuffer(FDescription[1], B);
      end;
    end;

  finally
    FS.Free;
  end;
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TFonFile.SaveToFile(const FileName: string);

const
  FontDirString: string[7] = 'FONTDIR';
  MZHeader: array [0..127] of Byte =
  (
    $4D, $5A, $FB, $00, $01, $00, $00, $00, $04, $00, $00, $00, $FF, $FF, $00, $00,
    $B8, $00, $00, $00, $00, $00, $00, $00, $40, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $00, $00, $00,
    $0E, $1F, $BA, $0E, $00, $B4, $09, $CD, $21, $B8, $01, $4C, $CD, $21, $54, $68,
    $69, $73, $20, $70, $72, $6F, $67, $72, $61, $6D, $20, $63, $61, $6E, $6E, $6F,
    $74, $20, $62, $65, $20, $72, $75, $6E, $20, $69, $6E, $20, $44, $4F, $53, $20,
    $6D, $6F, $64, $65, $2E, $0D, $0A, $24, $00, $00, $00, $00, $00, $00, $00, $00
  );

var
  Stream: TStream;
  I: Integer;

  ResourceTableSize: Integer;
  ResNameTableSize: Integer;
  ResourceStartOfs: Integer;
  FontDirResourceSize: Integer;
  FontStart: Integer;
  FontSize: Integer;

  NEHeader: TNEHeader;
  Alignment: Word;
  TypeId: Word;
  ResourceCount: Word;
  NotUsed: Longword;
  Res: TRes;
  Len: Byte;
  EntryIndex: Byte;
  Zero: Word;
  FontCount: Word;
  FontId: Word;
  FaceName: string;
  NullTerm: Byte;

  VersionStream: TMemoryStream;

begin
  VersionStream := TMemoryStream.Create;
  try
    SaveVersion(VersionStream);

    Stream := TFileStream.Create(FileName, fmCreate);
    try

      Stream.WriteBuffer(MZHeader[0], SizeOf(MZHeader));

      ResourceTableSize :=
        {Alignment}2 +
        {FontDir} ({TypeId}2 + {ResourceCount}2 + {NotUsed}4 + SizeOf(TRes)) +
        {Fonts}   ({TypeId}2 + {ResourceCount}2 + {NotUsed}4 + SizeOf(TRes) * FFonts.Count) +
        {Version} ({TypeId}2 + {ResourceCount}2 + {NotUsed}4 + SizeOf(TRes)) +
        {TypeId}2;

      ResNameTableSize := {Length}1 + Length(FModuleName) + {Index}1 + {end marker}1;

      with NEHeader do
      begin
        NESignature := $454E;
        LinkerVersion := 5;
        LinkerRevision := 1;
        EntryTableSize := 2;
        CheckSum := 0;
        Flags := $8300;
        AutoSegsCount := 0;
        HeapSize := 0;
        StackSize := 0;
        Entry_CS_IP := 0;
        Stack_SS_SP := 0;
        SegsCount := 0;
        ModulesCount := 0;
        NonResNameTableSize := {Length}1 + Length(FDescription) + {Index}1 + {end marker}1;
        SegTableOfs := SizeOf(TNEHeader);
        ResTableOfs := SegTableOfs;
        ResNameTableOfs := ResTableOfs + ResourceTableSize + {FontDirString length}1 + Length(FontDirString);
        EntryTableOfs := ResNameTableOfs + ResNameTableSize;
        ModuleTableOfs := EntryTableOfs;
        ImpNameTableOfs := ModuleTableOfs;
        NonResNameTableOfs := EntryTableOfs + {end marker}2 + Length(MZHeader);
        NotUsed1 := 0;
        MovableEntryCount := 0;
        Alignment := 4;
        ResSegsCount := 0;
        OSId := 2;
        ExtraFlags := 0;
        GangLoadSecOfs := 0;
        GangLoadSecSize := 0;
        NotUsed2 := 0;
        WindowsVersion := $030A;
      end;

      ResourceStartOfs := (((NEHeader.NonResNameTableOfs + NEHeader.NonResNameTableSize) + 15) div 16) * 16;

      FontDirResourceSize := {fonts count}2;
      for I := 0 to FFonts.Count-1 do
      begin
        Inc(FontDirResourceSize,
          ({id}2 + TFntFile.HeaderSize + {device name null-term}1 + Length(TFntFile(FFonts[I]).FaceName) + {null-term}1));
      end;
      FontDirResourceSize := ((FontDirResourceSize + 15) div 16) * 16;

      Stream.WriteBuffer(NEHeader, SizeOf(NEHeader));

      // Write resource alignment:
      Alignment := 4;
      Stream.WriteBuffer(Alignment, 2);

      // Write FontDir resource entry:
      TypeId := {RT_FONTDIR} 7 + $8000;
      Stream.WriteBuffer(TypeId, 2);
      ResourceCount := 1;
      Stream.WriteBuffer(ResourceCount, 2);
      NotUsed := 0;
      Stream.WriteBuffer(NotUsed, 4);
      Res.Ofs := ResourceStartOfs div 16;
      Res.Size := FontDirResourceSize div 16;
      Res.Flags := $0C50;
      Res.Id := ResourceTableSize;
      Res.Reserved := 0;
      Stream.WriteBuffer(Res, SizeOf(Res));

      // Write Font resource entries:
      TypeId := {RT_FONT} 8 + $8000;
      Stream.WriteBuffer(TypeId, 2);
      ResourceCount := FFonts.Count;
      Stream.WriteBuffer(ResourceCount, 2);
      NotUsed := 0;
      Stream.WriteBuffer(NotUsed, 4);
      FontStart := ResourceStartOfs + FontDirResourceSize;
      for I := 0 to FFonts.Count-1 do
      begin
        FontSize := ((TFntFile(FFonts[I]).StreamSize + 15) div 16) * 16;
        Res.Ofs := FontStart div 16;
        Res.Size := FontSize div 16;
        Res.Flags := $1C30;
        Res.Id := $8000 + (I + 1);
        Res.Reserved := 0;
        Stream.WriteBuffer(Res, SizeOf(Res));
        Inc(FontStart, FontSize);
      end;

      // Write Version resource entry:
      TypeId := {RT_VERSION} 16 + $8000;
      Stream.WriteBuffer(TypeId, 2);
      ResourceCount := 1;
      Stream.WriteBuffer(ResourceCount, 2);
      NotUsed := 0;
      Stream.WriteBuffer(NotUsed, 4);
      Res.Ofs := FontStart div 16;
      Res.Size := (VersionStream.Size + 15) div 16;
      Res.Flags := $0C30;
      Res.Id := $8000 + 1;
      Res.Reserved := 0;
      Stream.WriteBuffer(Res, SizeOf(Res));

      // Write end marker:
      TypeId := 0;
      Stream.WriteBuffer(TypeId, 2);

      // Write 'FONTDIR' string:
      Stream.WriteBuffer(FontDirString[0], {FontDirString length}1 + Length(FontDirString));

      // Write ResNamesTable:
      Assert(Stream.Position = Length(MZHeader) + NEHeader.ResNameTableOfs);
      Len := Length(FModuleName);
      Stream.WriteBuffer(Len, 1);
      Stream.WriteBuffer(FModuleName[1], Length(FModuleName));
      EntryIndex := 0;
      Stream.WriteBuffer(EntryIndex, 1);
      Len := 0;
      Stream.WriteBuffer(Len, 1);

      // Write Entry table end marker:
      Assert(Stream.Position = Length(MZHeader) + NEHeader.EntryTableOfs);
      Zero := 0;
      Stream.WriteBuffer(Zero, 2);

      // Write NonResNamesTable:
      Assert(Stream.Position = NEHeader.NonResNameTableOfs);
      Len := Length(FDescription);
      Stream.WriteBuffer(Len, 1);
      Stream.WriteBuffer(FDescription[1], Length(FDescription));
      EntryIndex := 0;
      Stream.WriteBuffer(EntryIndex, 1);
      Len := 0;
      Stream.WriteBuffer(Len, 1);

      // Write FontDir resource:
      WriteToAlign16Bytes(Stream);
      Assert(Stream.Position = ResourceStartOfs);
      FontCount := FFonts.Count;
      Stream.WriteBuffer(FontCount, 2);
      for I := 0 to FFonts.Count-1 do
      begin
        FontId := I + 1;
        Stream.WriteBuffer(FontId, 2);
        TFntFile(FFonts[I]).WriteHeaderToStream(Stream);
        NullTerm := {device name}0;
        Stream.WriteBuffer(NullTerm, 1);
        FaceName := TFntFile(FFonts[I]).FaceName;
        Stream.WriteBuffer(FaceName[1], Length(FaceName) + {null-term}1);
      end;

      // Write Font resources:
      for I := 0 to FFonts.Count-1 do
      begin
        WriteToAlign16Bytes(Stream);
        TFntFile(FFonts[I]).WriteToStream(Stream);
      end;

      // Write Version resource:
      WriteToAlign16Bytes(Stream);
      VersionStream.Position := 0;
      Stream.CopyFrom(VersionStream, VersionStream.Size);
      WriteToAlign16Bytes(Stream);

    finally
      Stream.Free;
    end;
  finally
    VersionStream.Free;
  end;
end;

//======================================================================================================================
end.


