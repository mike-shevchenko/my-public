unit XMLParsers {v1.1};

{ Mike.Shevchenko@gmail.com. Borland Delphi 7. Moscow, 2003-2009 }

interface


  uses
    SysUtils, Classes;


    
  type

  
    TXMLParserError =
    (
      cXMLError_WellFormedness,      // Well-formedness is violated.
      cXMLError_WrongName,           // Name is illegal.
      cXMLError_StructLimitation,    // XML construction is legal but currently not supported.
      cXMLError_WrongHandling,       // Invalid call is made or invalid parameters are passed.
      cXMLError_WrongEncoding,       // Encoding of XML stream is mislabeled or not supported.
      cXMLError_EncodingLimitation,  // XML stream is legal but contains not supported chars.
      cXMLError_UnexpectedEOF,       // XML stream terminated unexpectedly.
      cXMLError_WrongXMLDecl         // XML declaration ("<?xml") is wrong.
    );



    TXMLEncoding =
    (
      cXMLEncoding_Windows1251,
      cXMLEncoding_UTF8,
      cXMLEncoding_UTF16LE,
      cXMLEncoding_UTF16BE
    );



    EXMLParserError = class ( Exception )  // Inherited Message property contains an error message in English
    private
      FKind:         TXMLParserError;
      FContext:      WideString;
      FContextIndex: Integer;

      constructor Create ( Kind: TXMLParserError;  const Context: WideString = '';  ContextCenter: PWideChar = nil );

    public
      property    Kind:         TXMLParserError   read FKind;
      property    Context:      WideString        read FContext;
      property    ContextIndex: Integer           read FContextIndex;
    end;



    TXMLNodeKind =
    (
      cXMLNodeKind_Root,     // Root node containing (as children) root element, PIs and comments
      cXMLNodeKind_DocType,  // Node containing DocType information
      cXMLNodeKind_Element,  // XML element
      cXMLNodeKind_CDATA,    // PCDATA between other nodes or a CDATA section
      cXMLNodeKind_PI,       // Processing instruction
      cXMLNodeKind_Comment   // Comments
    );



    TXMLParser = class;



    TXMLNode = class
    private
      FParser:    TXMLParser;
      FParent:    TXMLNode;

      FKind:      TXMLNodeKind;
      FName:      WideString;
      FText:      WideString;
      FSystemID:  WideString;
      FPublicID:  WideString;
      FChild:     TXMLNode;

      FPAttReg:     Pointer;
      FAttRegIndex: Integer;
      FAttReg: array of record
        Present: Boolean;
        Value:   WideString;
      end;
      FAttIndex:    Integer;
      FAtts: array of record
        Name:    WideString;
        Value:   WideString;
      end;

      function    GetAtt ( const AttName: WideString ): WideString;

      constructor CreateRoot    ( Parser: TXMLParser );
      constructor CreateDocType ( Parser: TXMLParser );
      constructor CreateElement ( Parser: TXMLParser; Parent: TXMLNode );
      constructor CreateCDATA   ( Parser: TXMLParser; const Text: WideString; Parent: TXMLNode );
      procedure   ParseNextCharData (var Data: WideString; var Last: WideChar; NewLinesToSpaces: Boolean);
      procedure   LoadNextChild;

    public
      destructor  Destroy;  override;

      property    Parent:    TXMLNode      read FParent;   // Parent node for Element and CDATA; nil for others

      property    Kind:      TXMLNodeKind  read FKind;
      property    Name:      WideString    read FName;     // Element, PI (target) or DocType;  '' for others
      property    Text:      WideString    read FText;     // PI, CDATA or Comment;  '' for others
      property    SystemID:  WideString    read FSystemID; // DocType;  '' for others
      property    PublicID:  WideString    read FPublicID; // DocType;  '' for others
      property    Child:     TXMLNode      read FChild;    // Element and Root only;  nil for others
      function    NextChild: TXMLNode;                     // Element and Root only;  NOP for others
      property    Att [ const Name: WideString ]: WideString  read GetAtt;  // Element only;  '' for others

      {debug}function DumpToWideString ( Indent: Integer = 0 ): WideString;
    end;



    {implementation}

      PXMLAttReg     = ^TXMLAttReg;
      TXMLAttReg     = array of record  Name, DefaultValue: WideString  end;
      TXMLElementRec = record  Name: WideString;  AttReg: TXMLAttReg  end;
      
    {end implementation}



    TXMLParser = class
    private
      FStream:     TStream;
      FSource:     WideString;
      FPSource:    PWideChar;
      FEncoding:   TXMLEncoding;
      FDecodeStr:  procedure ( Stream: TStream;  var WS: WideString;  const Start: string );
      FStandalone: Boolean;

      FRoot:       TXMLNode;

      FElementReg: array {HashCode * 2} of TXMLElementRec;
      {
        Each hashcoded line is followed by the spare line (for duplicate hashcode strings).
        If the spare line is also occupied, the first empty of subsequent spare lines is used.
      }
      FHashCode:  Byte;  // Calculated by FindElement function.

      procedure   ContextError ( Kind: TXMLParserError );  // raise EXMLParserError.Create (Kind, FSource, FPSource);
      procedure   LoadNextBuf;  // Loads FSource (null-terminated even if empty (EOF)) and sets FPSource to FSource[1].

    private{friend}
      F: record case Byte of 0: (W: WideChar;); 1: (L, H: Char) end; // Current character from FSource.

      procedure   NextF;  // Loads next current character to F.W (#0 if end of stream).
      procedure   DemandWC ( WC: WideChar );   // Does  " if F.W <> WC then raise WellFormedness else NextF; ".
      procedure   DemandWS ( const WS: WideString );   // Demands a given string starting with F.W.
      procedure   DemandName ( var Name: WideString );  // Fills given string with current Name starting with F.W.
      procedure   SkipSpaces;  // Skips spaces starting from F.W (if any).
      function    ReadSpaces: WideString;  // Reads spaces starting from F.W (if any).
      procedure   DemandSpaces;  // Raises WellFormedness if not F.W in SpaceSet, then SkipSpaces.

      function    FindElement ( const Name: WideString ): PXMLAttReg;  // nil if not found

    public
      constructor Create;
      destructor  Destroy;  override;

      property    Encoding: TXMLEncoding  read FEncoding;
      property    Root: TXMLNode  read FRoot;
      procedure   RegisterAtt ( const ElementName, AttName, AttDefaultValue: WideString );
      procedure   StartParsing ( Stream: TStream;  IgnoreSpaces: Boolean = True );
      procedure   StopParsing;
    end;



  const
    XMLNameStartSet: set of Char = [':', 'A'..'Z', '_', 'a'..'z', #128..#255];
    XMLNameCharSet:  set of Char = [':', 'A'..'Z', '_', 'a'..'z', '-', '.', '0'..'9', #128..#255];


(*)

  Implementation Notes
 ======================

  This parser is a non-validating, conformant (with limitations stated here) to XML specification v1.0 Second Edition
  with Errata correction dated 06.08.2003. Limitations are specific to current version and are likely to be suppressed
  in future versions of the parser. Violations of limitations raise EXMLParserError with different Kinds.
  General limitations are marked with "L", limitations (widening) to char sets are marked with "C",
  limitations to XML structure are marked with "S" (exception Kind = cXMLError_StructLimitation),
  limitations to encodings support are marked with "E" (exception Kind = cXMLError_EncodingLimitation).
  Parser features which are allowed by the standard are marked with "*".

  *  The parser does NOT read any external entities.

  S  Documents with DTD internal subset are not supported.
  S  Attribute values containing references to general entities (except predefined) are not supported.
  S  Processing Instructions are not supported.
  S  CDATA sections are not supported.
  L  IgnoreSpaces flag should be always True (otherwise WrongHandling is raised).
  *  If IgnoreSpaces flag is set, PCDATA nodes containing only spaces are not generated.

  L  There may be several DocTypes and root elements, NextChild does not check for their reappearance.
  L  Version number may state "1.0" or "1.1". Version number is not considered during parsing.
  C  No check for surrogate consistency is performed (surrogates are not recognized).
  C  XML grammar production [2] Char is widened to: [#x1-#x10FFFF]. But in att values all chars < #x20 become #x20.
  C  XML grammar production [4] NameChar is widened to: ':' | [A-Z] | '_' | [a-z] | '-' | '.' | [0-9] | [#x80-#x10FFFF].
  C  XML grammar production [5] Name is widened to: (':' | [A-Z] | '_' | [a-z] | [#x80-#x10FFFF]) NameChar*.
  C  XML grammar production [12] PubidLiteral right part is replaced with production [11] SystemLiteral right part.

  *  All internal WideString processing is considered to be in UTF-16 or UCS-2.
  *  XML document entity stream should be encoded in "UTF-8", "UTF-16" or "Windows-1251".
  E  UTF-8 encoding does not support surrogates (4-byte sequences in UTF-8).
  E  UTF-16BE encoding is not supported.


  User's Guide
 ==============

  Statements marked with R are recomendations, marked with D are definitions, others describe parser behaviour.

  R  TXMLParser object should be created once for each document type.
  R  Call TXMLParser.RegisterAtt method for each known element and each known attribute, providing default value.
  D  Reading attribute values using TXMLNode.Att property is called "attributes scanning".
  D  Different "nodes" represent content parts like PIs (processing instructions), PCDATA and elements, respectively.
  *  XML root (document) element will be one of the Root children, other Root children may be PIs or CDATAs of spaces.
  *  If attributes are scanned in the order they appear in XML, it works faster.
  *  If attributes are registered and registration order is the order of their scanning, it works faster.
  *  Registration with TXMLParser.RegisterAtt method is not obligatory, it just speeds up attributes scanning.
  *  If attribute being scanned does not exist nor was registered with default value, an empty string is returned.
  *  TXMLParser.StartParsing creates Root element. When it exists, TXMLParser.RegisterAtt method should not be called.
  *  TXML.StopParsing destroys Root element (and assignes nil to it), but keeps att registration information.
  *  Having a TXMLNode, one always has its first child node (recursively). In order to get next child node in Child,
     TXMLNode.NextChild function should be called - it returns a copy of new Child property for convenience.
     After a call to TXMLNode.NextChild the Child property is nil if no more child nodes exist.
     Call to TXMLNode.NextChild is NOP if Child is already nil.
  *  If TXMLParser.StartParsing is called twice, it works as if TXMLParser.StopParsing was called between that calls.
  *  If TXMLParser.NextChild raises an exception, TMLParser.StopParsing is called automatically.

(*)




implementation



  uses
    TypInfo;



  const
    BufferSize = 16384;



  const
    SpaceSet: set of Char = [#$20, #$09, #$0D, #$0A];



{=======  EXMLParserError  ============================================================================================}


  constructor EXMLParserError.Create ( Kind: TXMLParserError;
                                       const Context: WideString = '';  ContextCenter: PWideChar = nil );
  const
    ContextLen = 32;
  var
    RLen, LLen: Integer;
    ContextStart: PWideChar;
    MsgContext: string;
    I: Integer;
  begin
    FKind := Kind;
    case FKind of
      cXMLError_WellFormedness:     inherited Create ('Well-formedness is violated.');
      cXMLError_WrongName:          inherited Create ('Name is illegal.');
      cXMLError_StructLimitation:   inherited Create ('XML construction is legal but currently not supported.');
      cXMLError_WrongHandling:      inherited Create ('Invalid call is made or invalid parameters are passed.');
      cXMLError_WrongEncoding:      inherited Create ('Encoding of XML stream is mislabeled or not supported.');
      cXMLError_WrongXMLDecl:       inherited Create ('XML declaration ("<?xml") is wrong.');
      cXMLError_EncodingLimitation: inherited Create ('XML stream is legal but contains not supported chars.');
      cXMLError_UnexpectedEOF:      inherited Create ('XML stream terminated unexpectedly.');
    else
      inherited Create ('Unknown error.')
    end{case};

    if (Context = '') or (Context[1] = #0) then Exit;

    if not Assigned(ContextCenter) or (ContextCenter^ = #0) then
    begin
      Message := Message + #13#10'Context: ' + QuotedStr(Context);
      Exit;
    end;

    ContextStart := @Context[1];
    RLen := 0;
    while (ContextCenter[RLen] <> #0) and (RLen < ContextLen div 2) do
      Inc (RLen);
    LLen := ContextLen - RLen;
    if LLen > ContextCenter - ContextStart then
      LLen := ContextCenter - ContextStart;
    SetLength (FContext, LLen + RLen);
    Move (ContextCenter[-LLen], FContext[1], (LLen+RLen) shl 1);
    FContextIndex := LLen + 1;

    MsgContext := FContext;
    for I := 1 to Length(MsgContext) do
      if MsgContext[I] < #32 then
        MsgContext[I] := #32;

    Message := Message + #13#10'Context: ';
    if LLen > 0 then
      Message := Message + QuotedStr(Copy(MsgContext, 1, LLen));
    Message := Message + ' !' + QuotedStr(Copy(MsgContext, LLen+1, MaxInt));
  end;




{=======  Decode functions  ===========================================================================================}


{
  procedure Decode_??? ( Stream: TStream;  var WS: WideString;  const Start: string );

  WS is already allocated. Its data should be overwritten, end char marked with #0 (length should remain original).
  WS should be filled with new portion from Stream. Length(WS) is always even.
  If Start is not empty, the function should behave as if Start bytes were appended to the beginning of the Stream.
  (For 16-bit formats, Length(Start) is always even.)
  If char #0 occurs in input data, WrongEncoding should be raised.
}


  // ATTENTION: Limited version
  procedure Decode_UTF8 ( Stream: TStream;  var WS: WideString;  const Start: string );
  var
    StartLen, Len: Integer;
    B: array [1..3] of Byte;
    W: WideChar;
    PW: PWideChar;
    I: Integer;
  begin
    if Start <> '' then
    begin
      StartLen := Length(Start);
      for I := 1 to StartLen do
        WS[I] := WideChar(Ord(Start[I]));
      PW := @WS[StartLen + 1];
    end
    else
    begin
      PW := @WS[1];
    end;

    // OPTIMIZE: Bufferred reading from the stream may work faster.

    while True do
    begin
      Len := Stream.Read(B[1], 1);
      if Len <> 1 then
        Break;

      if B[1] = 0 then
      begin
        raise EXMLParserError.Create (cXMLError_WrongEncoding);
      end
      else if B[1] < 128 then
      begin
        W := WideChar(B[1]);
      end
      else if (B[1] >= $C2) and (B[1] <= $DF) then
      begin
        // Two-byte sequence.
        Len := Stream.Read(B[2], 1);
        if Len <> 1 then
          raise EXMLParserError.Create (cXMLError_WrongEncoding);
        W := WideChar((B[1] and $1F) shl 6 + B[2] and $3F);
      end
      else if (B[1] >= $E0) and (B[1] <= $EF) then
      begin
        // Three-byte sequence.
        Len := Stream.Read(B[2], 2);
        if Len <> 2 then
          raise EXMLParserError.Create (cXMLError_WrongEncoding);
        W := WideChar( (B[1] and $0F) shl 12 + (B[2] and $3F) shl 6 + B[3] and $3F);
      end
      else if (B[1] >= $F0) and (B[1] <= $F4) then
      begin
        // Four-byte sequence.
        raise EXMLParserError.Create (cXMLError_EncodingLimitation);
      end
      else
        raise EXMLParserError.Create (cXMLError_WrongEncoding);

      PW^ := W;
      Inc(PW);
      if PW - @WS[1] = Length(WS) then
        Break;
    end;

    PW^ := #0;
  end;



  // ATTENTION: Limited version
  procedure Decode_UTF16BE ( Stream: TStream;  var WS: WideString;  const Start: string );
  begin
    // STUB
    raise EXMLParserError.Create (cXMLError_EncodingLimitation);
  end;



  procedure Decode_UTF16LE ( Stream: TStream;  var WS: WideString;  const Start: string );
  var
    StartLen, Len: Integer;
  begin
    if Start = '' then
      Len := Stream.Read (WS[1], Length(WS) shl 1) shr 1
    else
    begin
      StartLen := Length(Start);
      Move (Start[1], WS[1], StartLen);
      Len := ( StartLen  +
               Stream.Read (WS[StartLen shr 1], Length(WS) shl 1 - StartLen) ) shr 1;
    end;
    // OPTIMIZE: See System._LStrFromPChar: works 16% faster.
    asm
      MOV   ECX,Len
      TEST  ECX,ECX
      JZ    @exit
      PUSH  EDI
      MOV   EDI,WS
      MOV   EDI,[EDI]
      XOR   EAX,EAX
      REPNE SCASW
      JNZ   @finish
      MOV   Len,-1
    @finish:
      POP  EDI
    @exit:
    end;
    if Len = -1 then raise EXMLParserError.Create (cXMLError_WrongEncoding);
    WS[Len+1] := #0;
  end;



  procedure Decode_Windows1251 ( Stream: TStream;  var WS: WideString;  const Start: string );
  const
    Table: array [128..128+64-1] of Word =
    (
      1026, 1027, 8218, 1107, 8222, 8230, 8224, 8225, 8364, 8240, 1033, 8249, 1034, 1036, 1035, 1039,
      1106, 8216, 8217, 8220, 8221, 8226, 8211, 8212,  152, 8482, 1113, 8250, 1114, 1116, 1115, 1119,
       160, 1038, 1118, 1032,  164, 1168,  166,  167, 1025,  169, 1028,  171,  172,  173,  174, 1031,
       176,  177, 1030, 1110, 1169,  181,  182,  183, 1105, 8470, 1108,  187, 1112, 1029, 1109, 1111
    );
  var
    StartLen, Len, CurLen: Integer;
    PW: PWideChar;
    PS: PChar;
    C: Char;
  begin
    PS := @WS[1 + Length(WS) shr 1];
    if Start = '' then
      Len := Stream.Read (PS^, Length(WS))
    else
    begin
      StartLen := Length(Start);
      Move (Start[1], PS^, StartLen);
      Len := StartLen  +  Stream.Read ((PS+StartLen)^, Length(WS) - StartLen);
    end;
    CurLen := Len;
    PW := @WS[1];

    // OPTIMIZE:  Asm will work faster
    while CurLen > 0 do
    begin
      C := PS^;
      if C = #0 then raise EXMLParserError.Create (cXMLError_WrongEncoding);
      if C < #128 then
        PW^ := WideChar(C)
      else
        if C >= #192 then
          PW^ := WideChar($410+Ord(C)-192)
        else
          PW^ := WideChar(Table[Ord(C)]);
      Inc (PS);
      Inc (PW);
      Dec (CurLen);
    end;
    WS[Len+1] := #0;
  end;



{=======  TXMLParser  =================================================================================================}



  procedure TXMLParser.StartParsing ( Stream: TStream;  IgnoreSpaces: Boolean = True );
  var
    Start: string;
    Encoding: (c8, cUTF8, c16LE, c16BE);
    Decl: string;
    P: Integer;
    WC: WideChar;
    C: Char;
    EncodingDecl: string;
    S: string;
    Space: Boolean;
  begin
    if not IgnoreSpaces then raise EXMLParserError.Create (cXMLError_WrongHandling);
    StopParsing;
    FStream := Stream;
    SetLength (FSource, BufferSize);


    ///////  Build:  Decl (if any),  Start is the start of document text AFTER Decl (if any),  Encoding

    Decl := '';
    SetLength (Start, 4);
    if FStream.Read (Start[1], 4) < 4 then raise EXMLParserError.Create (cXMLError_WellFormedness);

    if (Start = #$00#$00#$FE#$FF) or (Start = #$FF#$FE#$00#$00) or (Start = #$00#$00#$FF#$FE) or
       (Start = #$FE#$FF#$00#$00) or (Start = #$00#$00#$00#$3C) or (Start = #$3C#$00#$00#$00) or
       (Start = #$00#$00#$3C#$00) or (Start = #$00#$3C#$00#$00) or (Start = #$4C#$6F#$A7#$94) then
      raise EXMLParserError.Create (cXMLError_WrongEncoding);

    if ((Start[1] = #$FF) and (Start[2] = #$FE)) or (Start[2] = #$00) then  // UTF-16LE
    begin
      if Start[2] <> #$00 then
        Start := Start[3] + Start[4];
      Encoding := c16LE;
      P := Length(Start)+1;
      if P <= 8 then
      begin
        SetLength(Start, 8);
        if FStream.Read(Start[P], 9-P) <> 9-P then raise EXMLParserError.Create (cXMLError_WellFormedness);
      end;
      if Start = '<'#0'?'#0'x'#0'm'#0 then
      begin
        SetLength (Start, 12);
        if FStream.Read(Start[9], 4) <> 4 then raise EXMLParserError.Create (cXMLError_WellFormedness);
        if (Start[9] = 'l') and (Start[10] = #0) and (Start[11] in SpaceSet) and (Start[12] = #0) then
        begin
          Decl := '<?xml' + Start[11];
          repeat
            if (FStream.Read(WC, 2) <> 2) or (WC > #127) then
              raise EXMLParserError.Create (cXMLError_WellFormedness);
            Decl := Decl + WC;
          until WC = '>';
          Start := '';
        end;
      end;
    end
    else
      if ((Start[1] = #$FE) and (Start[2] = #$FF)) or (Start[1] = #$00) then  // UTF-16BE
      begin
        if Start[1] <> #$00 then
          Start := Start[3] + Start[4];
        Encoding := c16BE;
        P := Length(Start)+1;
        if P <= 8 then
        begin
          SetLength(Start, 8);
          if FStream.Read(Start[P], 9-P) <> 9-P then raise EXMLParserError.Create (cXMLError_WellFormedness);
        end;
        if Start = #0'<'#0'?'#0'x'#0'm' then
        begin
          SetLength (Start, 12);
          if FStream.Read(Start[9], 4) <> 4 then raise EXMLParserError.Create (cXMLError_WellFormedness);
          if (Start[10] = 'l') and (Start[9] = #0) and (Start[12] in SpaceSet) and (Start[11] = #0) then
          begin
            Decl := '<?xml' + Start[12];
            repeat
              if (FStream.Read(WC, 2) <> 2) or (WC > #127) then
                raise EXMLParserError.Create (cXMLError_WellFormedness);
              WC := WideChar(Ord(WC) shl 8 + (Ord(WC) shr 8) and $00FF);
              Decl := Decl + WC;
            until WC = '>';
            Start := '';
          end;
        end;
      end
      else  // 8-bit encoding
      begin
        if Copy(Start, 1, 3) = #$EF#$BB#$BF then
        begin
          Encoding := cUTF8;
          Start := Start[4];
          if Start = '<' then
          begin
            SetLength (Start, 4);
            if FStream.Read(Start[2], 3) <> 3 then raise EXMLParserError.Create (cXMLError_WellFormedness);
          end;
        end
        else
          Encoding := c8;

        if Start = '<?xm' then
        begin
          SetLength (Start, 6);
          if FStream.Read(Start[5], 2) <> 2 then raise EXMLParserError.Create (cXMLError_WellFormedness);
          if (Start[5] = 'l') and (Start[6] in SpaceSet) then
          begin
            Decl := '<?xml' + Start[6];
            repeat
              if (FStream.Read(C, 1) <> 1) or (C > #127) then
                raise EXMLParserError.Create (cXMLError_WellFormedness);
              Decl := Decl + C;
            until C = '>';
            Start := '';
          end;
        end;
      end;

    ///////  Parse Decl (if any) and build EncodingDecl and FStandalone

    FStandalone := False;
    EncodingDecl := '';
    if Decl <> '' then
    begin
      // Decl starts with '<?xml'
      P := 6;
      while Decl[P] in SpaceSet do Inc (P);
      if Copy (Decl, P, Length('version')) <> 'version' then raise EXMLParserError.Create (cXMLError_WrongXMLDecl);
      Inc (P, Length('version'));
      while Decl[P] in SpaceSet do Inc (P);
      if Decl[P] <> '=' then raise EXMLParserError.Create (cXMLError_WrongXMLDecl);
      Inc (P);
      while Decl[P] in SpaceSet do Inc (P);
      S := Copy(Decl, P, Length('"1.0"'));
      if (S <> '"1.0"') and (S <> '''1.0''') then raise EXMLParserError.Create (cXMLError_WrongXMLDecl);
      Inc(P, Length('"1.0"'));
      Space := (Decl[P] in SpaceSet);
      while Decl[P] in SpaceSet do Inc (P);
      if Copy(Decl, P, Length('encoding')) = 'encoding' then
      begin
        if not Space then raise EXMLParserError.Create (cXMLError_WrongXMLDecl);
        Inc (P, Length('encoding'));
        while Decl[P] in SpaceSet do Inc (P);
        if Decl[P] <> '=' then raise EXMLParserError.Create (cXMLError_WrongXMLDecl);
        Inc (P);
        while Decl[P] in SpaceSet do Inc (P);
        C := Decl[P];
        Inc (P);
        if (C <> '"') and (C <> '''') then raise EXMLParserError.Create (cXMLError_WrongXMLDecl);
        if not ( Decl[P] in ['A'..'Z', 'a'..'z'] ) then raise EXMLParserError.Create (cXMLError_WrongXMLDecl);
        EncodingDecl := Decl[P];
        Inc (P);
        while Decl[P] in ['A'..'Z', 'a'..'z', '0'..'9', '.', '_', '-'] do
        begin
          EncodingDecl := EncodingDecl + Decl[P];
          Inc (P);
        end;
        if Decl[P] <> C then raise EXMLParserError.Create (cXMLError_WrongXMLDecl);
        Inc (P);
        Space := (Decl[P] in SpaceSet);
        while Decl[P] in SpaceSet do Inc (P);
      end;
      if Copy(Decl, P, Length('standalone')) = 'standalone' then
      begin
        if not Space then raise EXMLParserError.Create (cXMLError_WrongXMLDecl);
        Inc (P, Length('standalone'));
        while Decl[P] in SpaceSet do Inc (P);
        if Decl[P] <> '=' then raise EXMLParserError.Create (cXMLError_WrongXMLDecl);
        Inc (P);
        while Decl[P] in SpaceSet do Inc (P);
        S := Copy(Decl, P, Length('"yes"'));;
        if (S = '"yes"') or (S = '''yes''') then
        begin
          FStandalone := True;
          Inc (P, Length('"yes"'));
        end
        else
        begin
          S := Copy (Decl, P, Length('"no"'));
          if (S = '"no"') or (S = '''no''') then
            Inc (P, Length('"no"'))
          else
            raise EXMLParserError.Create (cXMLError_WrongXMLDecl);
        end;
        while Decl[P] in SpaceSet do Inc (P);
      end;
      if (Decl[P] <> '?') or (Decl[P+1] <> '>') then raise EXMLParserError.Create (cXMLError_WrongXMLDecl);
    end;


    ///////  Check that EncodingDecl (if any) coincides with Encoding, set FDecodeStr

    EncodingDecl := UpperCase(EncodingDecl);
    case Encoding of
      c8:
        if (EncodingDecl = '') or (EncodingDecl = 'UTF-8') then
        begin
          FEncoding := cXMLEncoding_UTF8;
          FDecodeStr := @Decode_UTF8;
        end
        else if EncodingDecl = 'WINDOWS-1251' then
        begin
          FEncoding := cXMLEncoding_Windows1251;
          FDecodeStr := @Decode_Windows1251;
        end
        else
          raise EXMLParserError.Create (cXMLError_WrongEncoding);
      cUTF8:
        if (EncodingDecl = '') or (EncodingDecl = 'UTF-8') then
        begin
          FEncoding := cXMLEncoding_UTF8;
          FDecodeStr := @Decode_UTF8;
        end
        else
          raise EXMLParserError.Create (cXMLError_WrongEncoding);
      c16LE:
        if (EncodingDecl = '') or (EncodingDecl = 'UTF-16') then
        begin
          FEncoding := cXMLEncoding_UTF16LE;
          FDecodeStr := @Decode_UTF16LE;
        end
        else
          raise EXMLParserError.Create (cXMLError_WrongEncoding);
      c16BE:
        if (EncodingDecl = '') or (EncodingDecl = 'UTF-16') then
        begin
          FEncoding := cXMLEncoding_UTF16BE;
          FDecodeStr := @Decode_UTF16BE;
        end
        else
          raise EXMLParserError.Create (cXMLError_WrongEncoding);
    end;


    FDecodeStr (FStream, FSource, Start);
    FPSource := @FSource[1];

    if FPSource^ = #0 then raise EXMLParserError.Create (cXMLError_WellFormedness);
    F.W := FPSource^;

    try
      FRoot := TXMLNode.CreateRoot (Self);
    except
      FSource := '';
      raise;
    end;
  end;



  procedure TXMLParser.StopParsing;
  begin
    if not Assigned(FRoot) then Exit;
    FreeAndNil (FRoot);
    FSource := '';
  end;



  procedure TXMLParser.ContextError ( Kind: TXMLParserError );
  var
    E: EXMLParserError;
  begin
    E := EXMLParserError.Create (Kind, FSource, FPSource);
    FSource := '';
    FreeAndNil (FRoot);
    raise E;
  end;



  procedure TXMLParser.LoadNextBuf;
  begin
    FDecodeStr (FStream, FSource, '');
    FPSource := @FSource[1];
  end;



  procedure TXMLParser.NextF;
  begin
    Inc (FPSource);
    F.W := FPSource^;
    if F.W <> #0 then Exit;
    LoadNextBuf;
    F.W := FPSource^;
  end;



  procedure TXMLParser.DemandWC ( WC: WideChar );
  begin
    if F.W <> WC then
      if F.W = #0 then
        raise EXMLParserError.Create (cXMLError_UnexpectedEOF)
      else
        raise EXMLParserError.Create (cXMLError_WellFormedness, FSource, FPSource);
    Inc (FPSource);
    F.W := FPSource^;
    if F.W <> #0 then Exit;
    LoadNextBuf;
    F.W := FPSource^;
  end;



  procedure TXMLParser.DemandWS ( const WS: WideString );
  var
    I: Integer;
  begin
    // OPTIMIZE:  Better compare string in FSource (loading next buf if necessary)
    for I := 1 to Length(WS) do
      DemandWC (WS[I]);
  end;



  procedure TXMLParser.SkipSpaces;
  begin
    while (F.H = #0) and (F.L in SpaceSet) do
    begin
      Inc (FPSource);
      F.W := FPSource^;
      if F.W <> #0 then Continue;
      LoadNextBuf;
      F.W := FPSource^;
    end;
  end;



  function TXMLParser.ReadSpaces: WideString;
  begin
    Result := '';
    while (F.H = #0) and (F.L in SpaceSet) do
    begin
      Result := Result + F.W;
      Inc (FPSource);
      F.W := FPSource^;
      if F.W <> #0 then Continue;
      LoadNextBuf;
      F.W := FPSource^;
    end;
  end;



  procedure TXMLParser.DemandSpaces;
  begin
    if (F.H <> #0) or not (F.L in SpaceSet) then
      raise EXMLParserError.Create (cXMLError_WellFormedness, FSource, FPSource);
    repeat
      NextF;
    until (F.H <> #0) or not (F.L in SpaceSet);
  end;



  procedure TXMLParser.DemandName ( var Name: WideString );
  begin
    // OPTIMIZE:  Pre-allocate Name in caller!
    if (F.H = #0) and not (F.L in XMLNameStartSet) then
      raise EXMLParserError.Create (cXMLError_WrongName, FSource, FPSource);
    Name := F.W;
    NextF;
    while (F.H <> #0) or (F.L in XMLNameCharSet) do
    begin
      Name := Name + F.W;
      NextF;
    end;
  end;



  constructor TXMLParser.Create;
  begin
    SetLength (FElementReg, 512);
  end;



  destructor TXMLParser.Destroy;
  begin
    FRoot.Free;
  end;



  function TXMLParser.FindElement ( const Name: WideString ): PXMLAttReg;  // nil if not found
  var
    N: Integer;
    L, P: ^TXMLElementRec;
  begin
    { The following code calculates a hash code for ElementName the following way:
      First two WideChars (which always exist) are scrolled 4 bits left, then XOR'ed with middle two WideChars scrolled
      2 bits left and then XOR'ed with last two WideChars.
      Then bytes 0(lowest) and 2 of this 32-bit value are XOR'ed together to get a hash code.
    }
    asm
      PUSH EBX
      MOV  EDX,Name         // EDX := Address of a first pair of WideChars
      MOV  ECX,[EDX-4]      // ECX := Length of WideString in bytes
      MOV  N,ECX
      MOV  EBX,[EDX+ECX-4]  // EBX := Last pair of WideChars
      SHR  ECX,1
      AND  CL,$FE
      MOV  ECX,[EDX+ECX]    // ECX := Middle pair of WideChars
      MOV  EDX,[EDX]        // EDX := First pair of WideChars

      SHL  ECX,2
      XOR  EBX,ECX
      SHL  EDX,4
      XOR  EBX,EDX

      MOV  EDX,EBX
      SHR  EDX,8            // DL := EDL
      XOR  BL,DH
      MOV  FHashCode[EAX],BL
      POP  EBX
    end;

    L := @FElementReg[High(FElementReg)];
    P := @FElementReg[FHashCode shl 1];

    if P.Name = '' then
    begin
      Result := nil;
      Exit;
    end;

    if CompareMem( @Name[1], @P.Name[1], N ) then
    begin
      Result := @P.AttReg;
      Exit;
    end
    else
      Inc( P );

    repeat
      if P.Name = '' then Break;
      if CompareMem( @Name[1], @P.Name[1], N ) then
      begin
        Result := @P.AttReg;
        Exit;
      end;
      Inc( P, 2 );
    until PChar(P) > PChar(L);

    Result := nil;
  end;



  procedure TXMLParser.RegisterAtt ( const ElementName, AttName, AttDefaultValue: WideString );

    procedure SetAtt ( I: Integer );
    begin
      FElementReg[I].Name := ElementName;
      SetLength( FElementReg[I].AttReg, 1 );
      FElementReg[I].AttReg[0].Name := AttName;
      FElementReg[I].AttReg[0].DefaultValue := AttDefaultValue;
    end;

  var
    P: PXMLAttReg;
    I: Integer;
  begin
    if Assigned(FRoot) or (ElementName = '') or (AttName = '') then
      raise EXMLParserError.Create (cXMLError_WrongHandling);

    P := FindElement( ElementName );
    if Assigned (P) then
    begin
      SetLength (P^, 1 + Length(P^));
      with P^[High(P^)] do
      begin
        Name := AttName;
        DefaultValue := AttDefaultValue;
      end;
      Exit;
    end;

    I := FHashCode shl 1;
    if FElementReg[I].Name = '' then
    begin
      SetAtt( I );
      Exit;
    end;
    Inc( I );
    repeat
      if FElementReg[I].Name = '' then
      begin
        SetAtt( I );
        Exit;
      end;
      Inc (I, 2);
    until I >= Length(FElementReg);
    SetLength( FElementReg, 2 + Length(FElementReg) );
    SetAtt( High(FElementReg) );
  end;




{=======  TXMLNode  ===================================================================================================}



  function TXMLNode.GetAtt ( const AttName: WideString ): WideString;
  var
    StartIndex: Integer;
  begin
    if Assigned(FPAttReg) then
    begin
      StartIndex := FAttRegIndex;
      repeat
        with TXMLAttReg(FPAttReg)[FAttRegIndex] do
          if AttName = Name then
            with FAttReg[FAttRegIndex] do
            begin
              if Present then
                Result := Value
              else
                Result := DefaultValue;
              Exit;
            end;
        Inc (FAttRegIndex);
        if FAttRegIndex = Length(TXMLAttReg(FPAttReg)) then
          FAttRegIndex := 0;
      until FAttRegIndex = StartIndex;
    end;
    if Assigned(FAtts) then
    begin
      StartIndex := FAttIndex;
      repeat
        with FAtts[FAttIndex] do
          if Name = AttName then
          begin
            Result := Value;
            Exit;
          end;
        Inc (FAttIndex);
        if FAttIndex = Length(FAtts) then
          FAttIndex := 0;
      until FAttIndex = StartIndex;
    end;
    Result := '';
  end;



  {debug}function TXMLNode.DumpToWideString ( Indent: Integer = 0 ): WideString;
  var
    I, A: Integer;
    Name: WideString;
  begin
    if not Assigned(Self) then
    begin
      Result := '<?nil?>';
      Exit;
    end;
    Result := '';
    for I := 1 to Indent do Result := Result + ' ';
    Name := Copy ( GetEnumName(TypeInfo(TXMLNodeKind), Ord(FKind)),  Length('cXMLNodeKind_')+1,  MaxInt );
    Result := Result + '<' + Name;

    case FKind of
      cXMLNodeKind_Root:
        {NOP};
      cXMLNodeKind_DocType:
        Result := Result + '  Name="' + FName + '"  PublicID="' + FPublicID + '"  SystemID="' + FSystemID + '" ';
      cXMLNodeKind_Element:
        Result := Result + '  Name="' + FName + '" ';
      cXMLNodeKind_CDATA:
        Result := Result + '  Text="' + FText + '" ';
      cXMLNodeKind_PI:
        Result := Result + '  Name="' + FName + '"  Text="' + FText + '" ';
      cXMLNodeKind_Comment:
        Result := Result + '  Text="' + FText + '" ';
    end;

    if not Assigned(FChild) and not Assigned(FAttReg) and not Assigned(FAtts) then
      Result := Result + '/>'#10
    else
    begin
      Result := Result + '>'#10;
      for A := 0 to High(FAttReg) do
      begin
        for I := 1 to Indent+2 do Result := Result + ' ';
        Result := Result + '<AttReg  Name="' + TXMLAttReg(FPAttReg)[A].Name +
                           '"  DefaultValue="' + TXMLAttReg(FPAttReg)[A].DefaultValue +
                           '"  Present="' + IntToStr(Ord(FAttReg[A].Present));
        if FAttReg[A].Present then
          Result := Result + '"  Value="' + FAttReg[A].Value;
        Result := Result + '" />'#10;
      end;
      for A := 0 to High(FAtts) do
      begin
        for I := 1 to Indent+2 do Result := Result + ' ';
        Result := Result + '<Att  Name="' + FAtts[A].Name + '"  Value="' + FAtts[A].Value + '" />'#10;
      end;

      Result := Result + FChild.DumpToWideString(Indent+2);
      for I := 1 to Indent do Result := Result + ' ';
      Result := Result + '</' + Name + '>'#10;
    end;
  end;



  procedure TXMLNode.LoadNextChild;
  var
    ClosingName: WideString;
    Last: WideChar;
    Data: WideString;
  begin
    with FParser do
    begin
      repeat
        Data := ReadSpaces;
        if (FKind = cXMLNodeKind_Root) and (F.W = #0) then Exit;
        if F.W <> '<' then
        begin
          Last := #0;
          while F.W <> '<' do
          begin
            if F.W = #0 then FParser.ContextError(cXMLError_UnexpectedEOF);
            ParseNextCharData(Data, Last, False);
          end;

          if Pos(']]>', Data) > 0 then
            FParser.ContextError (cXMLError_WellFormedness);
          FChild := TXMLNode.CreateCDATA(FParser, Data, Self);
          Exit;
        end;

        NextF; // Skip '<'.

        if F.W = '/' then
        begin
          NextF;
          DemandName (ClosingName);
          if ClosingName <> FName then
            FParser.ContextError (cXMLError_WrongName);
          DemandWC ('>');
          Exit;
        end;
        if F.W = '?' then FParser.ContextError (cXMLError_StructLimitation);
        if F.W <> '!' then Break;
        NextF;
        if F.W <> '-' then FParser.ContextError (cXMLError_StructLimitation);
        NextF;
        DemandWC ('-');
        repeat
          while F.W <> '-' do NextF;
          NextF;
        until F.W = '-';
        NextF;
        DemandWC ('>');
      until False;

      FChild := TXMLNode.CreateElement (FParser, Self);
    end;
  end;



  function TXMLNode.NextChild: TXMLNode;
  begin
    if not Assigned(FChild) then
    begin
      Result := nil;
      Exit;
    end;
    while Assigned(FChild.FChild) do
      FChild.NextChild;
    FreeAndNil (FChild);
    LoadNextChild;
    Result := FChild;
  end;



  constructor TXMLNode.CreateRoot ( Parser: TXMLParser );
  begin
    FKind := cXMLNodeKind_Root;
    FParser := Parser;
    with FParser do
      repeat
        SkipSpaces;
        DemandWC ('<');
        if F.W = '?' then FParser.ContextError (cXMLError_StructLimitation);
        if F.W <> '!' then
        begin
          FChild := TXMLNode.CreateElement (FParser, Self);
          Exit;
        end;
        NextF;
        if F.W = '-' then
        begin
          NextF;
          DemandWC ('-');
          repeat
            while F.W <> '-' do NextF;
            NextF;
          until F.W = '-';
          NextF;
          DemandWC ('>');
        end
        else
        begin
          FChild := TXMLNode.CreateDocType (FParser);
          Exit;
        end;
      until False;
  end;



  constructor TXMLNode.CreateDocType ( Parser: TXMLParser );  // F.W -> 'DOCTYPE'
  var
    Q: WideChar;
  begin
    FKind := cXMLNodeKind_DocType;
    FParser := Parser;
    with FParser do
    begin
      DemandWS ('DOCTYPE');
      DemandSpaces;
      DemandName (FName);
      SkipSpaces;
      if F.W = 'S' then
      begin
        NextF;
        DemandWS ('YSTEM');
        DemandSpaces;
        FSystemID := '';
        Q := F.W;
        if (Q <> '''') and (Q <> '"') then FParser.ContextError (cXMLError_WellFormedness);
        NextF;
        while F.W <> Q do
        begin
          FSystemID := FSystemID + F.W;
          NextF;
        end;
        NextF;
        SkipSpaces;
      end
      else if F.W = 'P' then
      begin
        NextF;
        DemandWS ('UBLIC');
        DemandSpaces;
        FPublicID := '';
        Q := F.W;
        NextF;
        if (Q <> '''') and (Q <> '"') then FParser.ContextError (cXMLError_WellFormedness);
        while F.W <> Q do
        begin
          FPublicID := FPublicID + F.W;
          NextF;
        end;
        NextF;
        DemandSpaces;
        FSystemID := '';
        Q := F.W;
        NextF;
        if (Q <> '''') and (Q <> '"') then FParser.ContextError (cXMLError_WellFormedness);
        while F.W <> Q do
        begin
          FSystemID := FSystemID + F.W;
          NextF;
        end;
        NextF;
        SkipSpaces;
      end;
      if F.W = '[' then FParser.ContextError (cXMLError_StructLimitation);
      DemandWC ('>');
    end;
  end;

  procedure TXMLNode.ParseNextCharData (var Data: WideString; var Last: WideChar; NewLinesToSpaces: Boolean);
  var
    EntName: WideString;
    Code: Longword;
  begin
    with FParser do
    begin
      if F.W = '<' then FParser.ContextError (cXMLError_WellFormedness);
      if F.W = '&'  then
      begin
        Last := #0;
        NextF;
        if F.W <> '#' then
        begin
          DemandName (EntName);
          DemandWC (';');
          if EntName = 'lt' then
            Data := Data + '<'
          else if EntName = 'gt' then
            Data := Data + '>'
          else if EntName = 'apos' then
            Data := Data + ''''
          else if EntName = 'quot' then
            Data := Data + '"'
          else if EntName = 'amp' then
            Data := Data + '&'
          else
            FParser.ContextError (cXMLError_StructLimitation);
        end
        else
        begin
          NextF;
          Code := 0;
          if F.W = 'x' then
          begin
            NextF;
            while (Code <= $10FFFF) and ( ((F.W >= '0') and (F.W <='9')) or
                                          ((F.W >= 'a') and (F.W <= 'f')) or
                                          ((F.W >= 'A') and (F.W <= 'F')) ) do
            begin
              if F.W <= '9' then
                Code := Code shl 4 + Ord(F.W) - Ord('0')
              else if F.W <= 'F' then
                Code := Code shl 4 + Ord(F.W) - Ord('A') + 10
              else
                Code := Code shl 4 + Ord(F.W) - Ord('a') + 10;
              NextF;
            end;
          end
          else
            while (Code <= $10FFFF) and (F.W >= '0') and (F.W <='9') do
            begin
              Code := Code * 10 + Ord(F.W) - Ord('0');
              NextF;
            end;
          if (Code = 0) or (Code > $10FFFF) then FParser.ContextError (cXMLError_WellFormedness);
          if Code <= $FFFF then
            Data := Data + WideChar(Code)
          else
          begin
            Code := Code - $10000;
            Data := Data + WideChar($D800 + Code shr 10) + WideChar($DC00 + Code and $03FF);
          end;
          DemandWC (';');
        end;
      end
      else
      begin
        if NewLinesToSpaces then
        begin
          if (F.W <> #10) or (Last <> #13) then
          begin
            if F.W <= #32 then
              Data := Data + #32
            else
              Data := Data + F.W;
          end;
        end
        else
        begin
          if F.W = #13 then
            Data := Data + #10
          else if (F.W = #10) and (Last = #13) then
            {NOP} // The preceding #13 already produced a new line.
          else
              Data := Data + F.W;
        end;
        Last := F.W;
        NextF;
      end;
    end;
  end;


  constructor TXMLNode.CreateElement ( Parser: TXMLParser; Parent: TXMLNode );
  // OPTIMIZE: Pre-allocate AttValue
  var
    AttName, AttValue: WideString;
    Last: WideChar;
    Q: WideChar;
    I: Integer;
    AttRegIndex: Integer;
    StartIndex: Integer;
    FoundIndex: Integer;

  begin
    FKind := cXMLNodeKind_Element;
    FParent := Parent;
    FParser := Parser;
    with FParser do
    begin
      DemandName (FName);
      FPAttReg := FParser.FindElement(FName);
      if Assigned(FPAttReg) then
      begin
        FPAttReg := PXMLAttReg(FPAttReg)^;
        SetLength (FAttReg, Length(TXMLAttReg(FPAttReg)));
        FillChar (FAttReg[0], Length(TXMLAttReg(FPAttReg))*SizeOf(FAttReg[0]), 0);
      end;
      AttRegIndex := 0;
      repeat
        SkipSpaces;
        if F.W = '/' then
        begin
          NextF;
          DemandWC ('>');
          Break;
        end;
        if F.W = '>' then
        begin
          NextF;
          LoadNextChild;
          Break;
        end;
        DemandName (AttName);
        SkipSpaces;
        DemandWC ('=');
        SkipSpaces;
        Q := F.W;
        if (Q <> '''') and (Q <> '"') then FParser.ContextError (cXMLError_WellFormedness);
        NextF;
        AttValue := '';
        Last := #0;
        while F.W <> Q do
          ParseNextCharData(AttValue, Last, True);
        NextF;

        if Assigned(FPAttReg) then
        begin
          StartIndex := AttRegIndex;
          FoundIndex := -1;
          repeat
            if AttName = TXMLAttReg(FPAttReg)[AttRegIndex].Name then
              FoundIndex := AttRegIndex;
            Inc (AttRegIndex);
            if AttRegIndex = Length(TXMLAttReg(FPAttReg)) then
              AttRegIndex := 0;
          until (FoundIndex >= 0) or (AttRegIndex = StartIndex);
          if FoundIndex >= 0 then
            with FAttReg[FoundIndex] do
            begin
              if Present then FParser.ContextError (cXMLError_WellFormedness);
              Present := True;
              Value := AttValue;
              Continue;
            end;
        end;
        if Assigned(FAtts) then
          for I := 0 to High(FAtts) do
            if FAtts[I].Name = AttName then FParser.ContextError (cXMLError_WellFormedness);
        SetLength (FAtts, Length(FAtts)+1);
        with FAtts[High(FAtts)] do
        begin
          Name := AttName;
          Value := AttValue;
        end;
      until False;
    end;
  end;




  constructor TXMLNode.CreateCDATA ( Parser: TXMLParser; const Text: WideString; Parent: TXMLNode );
  begin
    FKind := cXMLNodeKind_CDATA;
    FParent := Parent;
    FText := Text;
  end;




  destructor TXMLNode.Destroy;
  begin
    FChild.Free;
  end;



end.

