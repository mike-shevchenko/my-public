unit XMLWriters {v1.1};

{ Mike.Shevchenko@gmail.com. Borland Delphi 7. Moscow, 2003-2009 }

interface


  uses
    Classes;


    
  type


    TXMLEncoding = ( cXMLEncoding_UTF8,  cXMLEncoding_UTF16LE,  cXMLEncoding_Windows1251 );


    TXMLWriter = class
    private
      FStream:      TStream;
      FEncoding:    TXMLEncoding;
      FLineBreak:   WideString;
      FSpaceAtts:   Boolean;
      FSpaceEqs:    Boolean;
      FUseIndents:  Boolean;
      FIndent:      Integer;

      FStartTag:    Boolean;
      FHasAtts:     Boolean;
      FSource:      WideString;
      FSourceIndex: Integer;
      FBuffer:      array of Byte;

      FEncodeStr: procedure ( Stream: TStream;  const WS: WideString;  PBuffer: PChar );

      procedure   WriteWS ( const Text: WideString );
      procedure   WriteWC ( WC: WideChar );
      procedure   WriteIndent;
      procedure   CloseTag;

    public
      constructor Create ( Stream: TStream;  Encoding: TXMLEncoding = cXMLEncoding_UTF16LE;  WriteBOM: Boolean = True;  
                           LineBreak: WideString = #13#10;  UseIndents: Boolean = True;  Indent: Integer = 0;
                           SpaceAtts: Boolean = False;  SpaceEqs: Boolean = False );
      destructor  Destroy;  override;
      procedure   Flush;

      property    Stream:     TStream       read FStream;
      property    Encoding:   TXMLEncoding  read FEncoding;
      property    UseIndents: Boolean       read FUseIndents;

      property    SpaceAtts:  Boolean  read FSpaceAtts   write FSpaceAtts;
      property    SpaceEqs:   Boolean  read FSpaceEqs    write FSpaceEqs;
      property    Indent:     Integer  read FIndent      write FIndent;

      procedure   WriteXMLDecl ( const XMLVersion: string = '1.0';  Standalone: Integer {0, 1, -1} = -1 );
      procedure   WriteDocType ( const Name: WideString;
                                 const SystemID: WideString = '';  const PublicID: WideString = '' );
      procedure   StartElement ( const Name: WideString );
      procedure   WriteAtt ( const Name, Value: WideString;  DoubleQuotes: Boolean = True );
      procedure   FinishElement ( const Name: WideString );
      procedure   WriteComment ( const Text: WideString );
      procedure   WriteNewLine;
    end;

(*)

  Implementation Notes
 ======================

  This XML writer is capable to produce any possible XML documents (with limitations stated here) conformant to
  XML specification v1.0 Second Edition with Errata correction dated 06.08.2003. Limitations are specific to current
  version and are likely to be suppressed in future versions of the writer. General limitations are marked with "L".
  Limitations to the character set support is marked with "E". Violations of limitations raise Exception with Message
  in English. The same exception occurs for incorrect call order (e.g. adding an att not at the element beginning).
  If a stream write error occurs, EWriteError exception is raised.

  L  DTD internal subset is not supported.
  L  Attribute values containing references to general entities (except predefined) are not supported.
  L  Processing Instructions are not supported.
  L  CDATA sections and PCDATA content are both not supported.
  L  XML grammar production [2] Char is widened to: [#x1-#x10FFFF].
  L  In attribute values all chars < #x20 become char refs with decimal code.
  L  UTF-16BE encoding is not supported.

  *  The writer writes ONLY the document entity.
  *  There may be several DocTypes and root elements, no check is performed for their reappearance.
  *  No check for Names, Version, SystemID and PublicID is performed for optimization.
  *  No check for Comment text is performed. Note that "--" is not allowed in comments, and they must not end with "-".
  *  No check for surrogate consistency is performed (surrogates are not recognized).
  *  All internal WideString processing is considered to be in UTF-16 or UCS-2.


  E  If "Windows-1251" is used, only 32 upper- and 32 lower-case Russian letters are permitted in addition to ASCII.
  E  If "UTF-8" is used, only codepoints less than $FFFF are supported, others produce invalid UTF-8 stream.

  User's Guide
 ==============

  Just create TXMLWriter object, give it an existing stream, and use its procedures to write XML.
  It is recommended to start with WriteXMLDecl.  Standalone < 0 means don't write SDDecl at all.
  Be sure to nest StartElement and FinishElement correctly and provide FinishElement the same name as StartElement.
  Note that destructor as well as WriteNewLine close start tag if it was not closed.
  Use Flush procedure to explicitly make internal buffer save to stream (destructor calls Flush automatically).

(*)


implementation



  uses
    SysUtils;


  const
    BufferWideCharSize = 8192;


{=======  Encode functions  ===========================================================================================}

{
  procedure Encode_??? ( Stream: TStream;  const WS: WideString;  PBuffer: PChar );

  WS contains data to be written.  PBuffer points to a buffer which size is at least 2 byte sizes of PWC string.
}



  procedure Encode_UTF8 ( Stream: TStream;  const WS: WideString;  PBuffer: PChar );
  // OPTIMIZE: Asm check for unsupported chars will work faster
  var
    I: Integer;
    P: Integer;
    C: Word;
  begin
    P := 0;
    for I := 1 to Length(WS) do
    begin
      C := Ord(WS[I]);
      if C < $80 then
      begin
        PBuffer[P] := Char(C);
        Inc(P);
      end
      else if C < $800 then
      begin
        PBuffer[P] := Char(6 shl 5 + C shr 6);
        Inc(P);
        PBuffer[P] := Char(2 shl 6 + C and $3F);
        Inc(P);
      end
      else
      begin
        PBuffer[P] := Char(14 shl 4 + C shr 12);
        Inc(P);
        PBuffer[P] := Char(2 shl 6 + Word(C shl 4) shr 10);
        Inc(P);
        PBuffer[P] := Char(2 shl 6 + C and $3F);
        Inc(P);
      end;
    end;
    Stream.WriteBuffer (PBuffer^, P);
  end;



  procedure Encode_UTF16LE ( Stream: TStream;  const WS: WideString;  PBuffer: PChar );
  begin
    Stream.WriteBuffer (WS[1], Length(WS) shl 1);
  end;



  procedure Encode_Windows1251 ( Stream: TStream;  const WS: WideString;  PBuffer: PChar );
  // OPTIMIZE: Asm will work faster
  var
    I: Integer;
  begin
    for I := 1 to Length(WS) do
      if Ord(WS[I]) < 128 then
        PBuffer[I-1] := Char(WS[I])
      else if (Ord(WS[I]) >= $410) and (Ord(WS[I]) <= $410+63) then
        PBuffer[I-1] := Chr(Ord(WS[I])-$410+192)
      else
        raise Exception.Create ('Windows-1251 writer:  Unsupported char: #' + IntToStr(Ord(WS[I])) + '.');
    Stream.WriteBuffer (PBuffer^, Length(WS));
  end;



{=======  TXMLWriter privates  ========================================================================================}



  procedure TXMLWriter.WriteWS ( const Text: WideString );
  var
    Len, Room: Integer;
  begin
    Len := Length(Text);
    Room := BufferWideCharSize - FSourceIndex + 1;
    if Room >= Len then
    begin
      Move (Text[1], FSource[FSourceIndex], Len shl 1);
      Inc (FSourceIndex, Len);
      Exit;
    end;
    Move (Text[1], FSource[FSourceIndex], Room shl 1);
    FEncodeStr (FStream, FSource, @FBuffer[0]);
    FSourceIndex := 1;

    WriteWS ( Copy(Text, Room+1, MaxInt) );
  end;



  procedure TXMLWriter.WriteWC ( WC: WideChar );
  begin
    if FSourceIndex <= BufferWideCharSize then
    begin
      FSource[FSourceIndex] := WC;
      Inc (FSourceIndex);
      Exit;
    end;

    FEncodeStr (FStream, FSource, @FBuffer[0]);
    FSource[1] := WC;
    FSourceIndex := 2;
  end;



  procedure TXMLWriter.WriteIndent;
  var
    I: Integer;
  begin
    // OPTIMIZE
    if FUseIndents then
      for I := 1 to FIndent do
        WriteWC (' ');
  end;

                                       

  procedure TXMLWriter.CloseTag;
  begin
    if FSpaceAtts and FHasAtts then
      WriteWS (' >')
    else
      WriteWC ('>');
    WriteWS (FLineBreak);
    FStartTag := False;
  end;




{=======  TXMLWriter publics  =========================================================================================}



  constructor TXMLWriter.Create ( Stream: TStream;  Encoding: TXMLEncoding = cXMLEncoding_UTF16LE;
                                  WriteBOM: Boolean = True;  
                                  LineBreak: WideString = #13#10;  UseIndents: Boolean = True;  Indent: Integer = 0;
                                  SpaceAtts: Boolean = False;  SpaceEqs: Boolean = False );
  const
    BOM_UTF8    = #$EF#$BB#$BF;
    BOM_UTF16LE = #$FF#$FE;

  begin
    FStream     := Stream;
    FEncoding   := Encoding;
    FLineBreak  := LineBreak;
    FSpaceAtts  := SpaceAtts;
    FSpaceEqs   := SpaceEqs;
    FUseIndents := UseIndents;
    FIndent     := Indent;

    SetLength (FBuffer, 4 * BufferWideCharSize);
    SetLength (FSource, BufferWideCharSize);
    FSourceIndex := 1;

    case FEncoding of
      cXMLEncoding_UTF8:
      begin
        FEncodeStr := @Encode_UTF8;
        if WriteBOM then
          FStream.WriteBuffer(BOM_UTF8[1], Length(BOM_UTF8));
      end;
      cXMLEncoding_UTF16LE:
      begin
        FEncodeStr := @Encode_UTF16LE;
        if WriteBOM then
          FStream.WriteBuffer(BOM_UTF16LE[1], Length(BOM_UTF16LE));
      end;
      cXMLEncoding_Windows1251:
        FEncodeStr := @Encode_Windows1251;
    end{case};
  end;



  destructor TXMLWriter.Destroy;
  begin
    if FStartTag then
      CloseTag;
    if FSourceIndex > 0 then
    begin
      SetLength (FSource, FSourceIndex-1);
      FEncodeStr (FStream, FSource, @FBuffer[0]);
    end;
  end;



  procedure TXMLWriter.Flush;
  var
    Len: Integer;
  begin
    if FSourceIndex > 0 then
    begin
      Len := Length (FSource);
      SetLength (FSource, FSourceIndex-1);
      FEncodeStr (FStream, FSource, @FBuffer[0]);
      SetLength (FSource, Len);
    end;
  end;



  procedure TXMLWriter.WriteXMLDecl ( const XMLVersion: string = '1.0';  Standalone: Integer {0, 1, -1} = -1 );
  begin
    if FStartTag then
      CloseTag;
    WriteIndent;
    WriteWS ('<?xml ');
    if FSpaceAtts then WriteWC (' ');
    WriteWS ('version');
    if FSpaceEqs then WriteWS (' = "') else WriteWS ('="');
    WriteWS (XMLVersion);
    WriteWC ('"');
    if FSpaceAtts then WriteWC (' ');
    WriteWS (' encoding');
    if FSpaceEqs then WriteWS (' = "') else WriteWS ('="');
    case FEncoding of
      cXMLEncoding_UTF8:         WriteWS ('UTF-8"');
      cXMLEncoding_UTF16LE:      WriteWS ('UTF-16"');
      cXMLEncoding_Windows1251:  WriteWS ('Windows-1251"');
    end{case};

    if Standalone >= 0 then
    begin
      if FSpaceAtts then WriteWC (' ');
      WriteWS (' standalone');
      if FSpaceEqs then WriteWS (' = "') else WriteWS ('="');
      if Standalone = 0 then
        WriteWS ('"no"')
      else
        WriteWS ('"yes"');
    end;

    if FSpaceAtts then WriteWC (' ');
    WriteWS ('?>');
    WriteWS (FLineBreak);
  end;



  procedure TXMLWriter.WriteDocType ( const Name: WideString;
                                      const SystemID: WideString = '';  const PublicID: WideString = '' );
  begin
    if FStartTag then
      CloseTag;
    WriteIndent;
    WriteWS ('<!DOCTYPE ');
    WriteWS (Name);
    if PublicID = '' then
      if SystemID <> '' then
      begin
        if FSpaceAtts then WriteWC (' ');
        WriteWS (' SYSTEM "');
        WriteWS (SystemID);
        WriteWS ('"');
        if FSpaceAtts then WriteWC (' ');
        WriteWC ('>');
      end
      else
      begin
        if FSpaceAtts then WriteWC (' ');
        WriteWC ('>');
      end
    else
    begin
      if FSpaceAtts then WriteWC (' ');
      WriteWS (' PUBLIC "');
      WriteWS (PublicID);
      WriteWC ('"');
      if SystemID <> '' then
      begin
        WriteWS (' "');
        WriteWS (SystemID);
        WriteWC ('"');
      end;
      if FSpaceAtts then WriteWC (' ');
      WriteWC ('>');
    end;
    WriteWS (FLineBreak);
  end;



  procedure TXMLWriter.StartElement ( const Name: WideString );
  begin
    if FStartTag then
      CloseTag;
    WriteIndent;
    FStartTag := True;
    FHasAtts := False;
    WriteWC ('<');
    WriteWS (Name);
    Inc (FIndent, 2);
  end;



  procedure TXMLWriter.FinishElement ( const Name: WideString );
  begin
    Dec (FIndent, 2);
    if FIndent < 0 then
      FIndent := 0;
    if FStartTag then
    begin
      if FSpaceAtts and FHasAtts then
        WriteWS (' />')
      else
        WriteWS ('/>');
      FStartTag := False;
    end
    else
    begin
      WriteIndent;
      WriteWS ('</');
      WriteWS (Name);
      WriteWC ('>');
    end;
    WriteWS (FLineBreak);
  end;



  procedure TXMLWriter.WriteAtt ( const Name, Value: WideString;  DoubleQuotes: Boolean = True );
  var
    I: Integer;
    Q: WideChar;
  begin
    if not FStartTag then raise Exception.Create ('TXMLWriter.WriteAtt: Not writing element start tag now.');
    FHasAtts := True;
    WriteWC (' ');
    if FSpaceAtts then WriteWC (' ');
    WriteWS (Name);
    if FSpaceEqs then WriteWS (' = ') else WriteWC ('=');
    if DoubleQuotes then
      Q := '"'
    else
      Q := '''';
    WriteWC (Q);
    for I := 1 to Length(Value) do
    begin
      if Value[I] = #0 then raise Exception.Create ('TXMLWriter.WriteAtt: #0 char occured.');
      if Value[I] < #32 then
      begin
        WriteWS ('&#');
        WriteWS (IntToStr(Ord(Value[I])));
        WriteWC (';');
      end
      else if Value[I] = '<' then
        WriteWS ('&lt;')
      else if Value[I] = '&' then
        WriteWS ('&amp;')
      else if Value[I] = Q then
        if DoubleQuotes then
          WriteWS ('&quot;')
        else
          WriteWS ('&apos;')
      else
        WriteWC (Value[I]);
    end;
    WriteWC (Q);
  end;



  procedure TXMLWriter.WriteComment ( const Text: WideString );
  begin
    if FStartTag then
      CloseTag;
    WriteIndent;
    WriteWS ('<!--');
    WriteWS (Text);
    WriteWS ('-->');
    WriteWS (FLineBreak);
  end;



  procedure TXMLWriter.WriteNewLine;
  begin
    if FStartTag then
      CloseTag;
    WriteWS (FLineBreak);
  end;



end.

