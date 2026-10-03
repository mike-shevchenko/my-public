unit XMLObjects {v1.3};

interface


  uses
    SysUtils, Classes, Contnrs,
    XMLWriters, XMLParsers;



  type

    TXMLObjectError =
    (
      cXMLObjectError_PropertyTypeNotSupported,  // Type of the property is not supported for XML streaming.
      cXMLObjectError_WrongConstantName,         // Enum constant name does not satisfy required scheme. 
      cXMLObjectError_WrongAttValue,             // Attribute value 'FValue' is illegal in this context.
      cXMLObjectError_ElementNotFound,           // Element 'FValue' expected but not found.
      cXMLObjectError_WrongElement,              // Unexpected element 'FValue' found.
      cXMLObjectError_WrongVersion               // Object model version 'FValue' is too low.
    );


    EXMLObjectError = class ( Exception )  // Inherited Message property contains an error message in English
    private
      FKind:           TXMLObjectError;
      FNameOfClass:    string;
      FNameOfProperty: string;
      FValue:          WideString;

      constructor Create ( Kind: TXMLObjectError;  const NameOfClass: string = '';  const NameOfProperty: string = '';
                           const Value: WideString = '' );

    public
      property    Kind:           TXMLObjectError   read FKind;
      property    NameOfClass:    string            read FNameOfClass;
      property    NameOfProperty: string            read FNameOfProperty;
      property    Value:          WideString        read FValue;
    end;


    {$TYPEINFO ON}
      TXMLObject          = class;
    {$TYPEINFO OFF}
    TXMLNamedObject     = class;
    TXMLObjectClass     = class of TXMLObject;
    TXMLObjectRegistry  = class;
    TXMLObjectListClass = class of TXMLObjectList;



    TXMLObjectList = class ( TObjectList )
    private
      FOwner: TXMLObject;
      function GetIt ( I: Integer ): TXMLObject;
    public
      class function ItemClass: TXMLObjectClass;  virtual;
      property Owner: TXMLObject  read FOwner  write FOwner;
      property It [ I: Integer ]: TXMLObject  read GetIt;  default;
      function Include ( Obj: TXMLObject;  P: Integer = -1 ): TXMLObject;

      function XMLString ( const LineBreak: WideString = #13#10;  Indent: Integer = 0;
        SpaceAtts: Boolean = False;  SpaceEqs: Boolean = False ): WideString;
    end;


    EDuplicateError = class(Exception)
    private
      FName: WideString;

    public
      constructor Create( const Name: WideString );

      property Name: WideString read FName;
    end;


    TXMLNamedObjectList = class(TXMLObjectList)
    public
      function FindByName( const Name: WideString;  Exclude: TXMLNamedObject = nil ): TXMLNamedObject;
      procedure CheckDuplicates;
    end;


(*) template< TTemplate(TXMLObject) >

  TTemplateList = class ( TXMLObjectList )
    private function GetIt ( I: Integer ): TTemplate;
    public  class function ItemClass: TXMLObjectClass;  override;
    public  property It [ I: Integer ]: TTemplate  read GetIt;  default;
    public  function Include ( Obj: TTemplate;  P: Integer = -1 ): TTemplate;
  end;

class function TTemplateList.ItemClass: TXMLObjectClass;  begin  Result := TTemplate  end;
function TTemplateList.GetIt ( I: Integer ): TTemplate;  begin  Result := List^[I]  end;
function TTemplateList.Include ( Obj: TTemplate;  P: Integer = -1 ): TTemplate;
  begin  Obj.Owner := Owner; Obj.OwnerList := Self; if P = -1 then Add(Obj) else Insert(P, Obj); Result := Obj;  end;

(*)



(*) template< TTemplate(TXMLObject) >

  TTemplateList = class ( TXMLNamedObjectList )
    private function GetIt ( I: Integer ): TTemplate;
    public  class function ItemClass: TXMLObjectClass;  override;
    public  property It [ I: Integer ]: TTemplate  read GetIt;  default;
    public  function Include ( Obj: TTemplate;  P: Integer = -1 ): TTemplate;
    public  function FindByName( const Name: WideString;  Exclude: TTemplate = nil ): TTemplate;
  end;

class function TTemplateList.ItemClass: TXMLObjectClass;  begin  Result := TTemplate  end;
function TTemplateList.GetIt ( I: Integer ): TTemplate;  begin  Result := List^[I]  end;
function TTemplateList.Include ( Obj: TTemplate;  P: Integer = -1 ): TTemplate;
  begin  Obj.Owner := Owner; Obj.OwnerList := Self; if P = -1 then Add(Obj) else Insert(P, Obj); Result := Obj;  end;
function TTemplateList.FindByName( const Name: WideString;  Exclude: TTemplate = nil ): TTemplate;
  begin Result := TTemplate(inherited FindByName(Name, Exclude)) end;

(*)


    TXMLNameList = class
    private
      FCount:     Integer;

      function    GetSpacedValues: WideString;
      procedure   SetSpacedValues ( const SpacedValues: WideString );  {raises EConvertError}
      function    GetCommaSpacedValues: WideString;
      procedure   SetCommaSpacedValues ( const CommaSpacedValues: WideString );  {raises EConvertError}

    public
      Names:      array of WideString;  // Use Count property; treat Length(Names) as TStringList.Capacity property

      property    Count: Integer  read FCount;

      property    SpacedValues:      WideString  read GetSpacedValues       write SetSpacedValues;
      property    CommaSpacedValues: WideString  read GetCommaSpacedValues  write SetCommaSpacedValues;

      class procedure ValidateCommaSpacedValues ( const CommaSpacedValues: WideString ); {raises EConvertError}

      procedure   Clear;
      procedure   Move     ( CurIndex, NewIndex: Integer );
      function    Add      ( const WS: WideString ): Integer;
      procedure   Insert   ( Index: Integer;  const WS: WideString );
      procedure   Delete   ( Index: Integer );
      procedure   Exchange ( Index1, Index2: Integer );
      function    IndexOf  ( const WS: WideString): Integer;  // -1 if not found.
      procedure   Assign   ( Source: TXMLNameList );
    end;




    {$TYPEINFO ON}

    TXMLObject = class
    private
      constructor CreateFromXMLNode ( XMLNode: TXMLNode;  XMLObjectRegistry: TXMLObjectRegistry );
      procedure   WriteToXMLWriter  ( XMLWriter: TXMLWriter );

    protected
      constructor CreateFromXMLStream ( Stream: TStream;  XMLObjectRegistry: TXMLObjectRegistry );
      procedure   SaveToXMLStream     ( Stream: TStream;  const Version: string = '';  const Description: string = '';
                                        Encoding: TXMLEncoding = cXMLEncoding_UTF16LE;
                                        const LineBreak: WideString = #13#10;  UseIndents: Boolean = True;
                                        SpaceAtts: Boolean = False;  SpaceEqs: Boolean = False );
    public
      ExtraInt:   Integer;
      ExtraObj:   TObject;
      ExtraPtr:   Pointer;
      ExtraStr:   string;
      OnDestroy:  procedure ( Sender: TXMLObject ) of object;

      Owner:      TXMLObject;
      OwnerList:  TXMLObjectList;

      constructor Create;   virtual;   // Create all lists and assign default property values
      destructor  Destroy;  override;  // Destroy all lists and their contents
      function    Clone:  TXMLObject;  // Only published properties are copied
      function    Remove: TXMLObject;  // Remove from OwnerList (if any) and return Self
      function    ReplaceWith ( XMLObject: TXMLObject ): {XMLObject}TXMLObject;
      function    GetIndex: Integer;
      function    Next(Index: Integer = -1): TXMLObject;  // Returns next sibling of Owner or nil if it is impossible.
      function    Prev(Index: Integer = -1): TXMLObject;  // Returns previous sibling of Owner or nil if it is impossible.

      function    XMLString ( const LineBreak: WideString = #13#10;  Indent: Integer = 0;
                              SpaceAtts: Boolean = False;  SpaceEqs: Boolean = False ): WideString;
    end;

    TXMLNamedObject = class(TXMLObject)
    private
      FName: WideString;

    published
      property Name: WideString read FName write FName;
    end;

    {$TYPEINFO OFF}



     TXMLObjectRegistry = class
     private
       FList:         TStringList;
       FOrderedList:  TStringList;
       FXMLParser:    TXMLParser;
       FOMName:       string;
       FReadsVersion: string;

     private{friend}
       function    Find ( const XMLElementName: string ): TXMLObjectClass;  overload;  // nil if not found
       function    Find ( XMLObjectClass: TXMLObjectClass ): string;  overload;  // '' if not found
       property    XMLParser: TXMLParser  read FXMLParser;
       property    OMName: string  read FOMName;  // Set by first call to Register;  always ends with 'OM'

     public
       constructor Create ( const ReadsVersion: string = '' );
       destructor  Destroy;  override;

       property    ReadsVersion: string  read FReadsVersion;

       procedure   Register ( XMLObjectClass: TXMLObjectClass );

       function    MakeDTD ( Root: TXMLObjectClass;
                             const Version: string = '';  const Description: string = '';
                             const LineBreak: string = #13#10 ): string;
     end;


(*)

  User's Guide
 ==============

     Create derived classes with published properties for attributes and for elements, compiled with {$TYPERINFO ON}.
     Corresponding XML will have the root element named the same as the unit with those derived classes, declared as:

       <!ELEMENT XOM (Root)>
       <!ATTLIST XOM
         version     CDATA ""
         description CDATA #IMPLIED
       >

     Here XOM is the name of the unit with derived classes, (Root) is the name of the root element.

     TXMLObjectRegistry.MakeDTD generates DTD with the following entities for predefined data types:

       <!ENTITY % Boolean-     "(False | True)"   >
       <!ENTITY % Integer-     "CDATA"          >
       <!ENTITY % Float-       "CDATA"          >
       <!ENTITY % AnsiString-  "CDATA #IMPLIED" >
       <!ENTITY % WideString-  "CDATA #IMPLIED" >
       <!ENTITY % NameList-    "NMTOKENS"       >
       <!ENTITY % Color-       "CDATA"          >

     Each enumerated type generates entity like the following:

       <!ENTITY % Enum "(E1|...|E2)">

     Each set type generates entity like the following (here Enum is the name of base enumerated type):

       <!ENTITY % EnumSet "NMTOKENS">

     Enumerated types constants in Pascal should be named in form "c@Enum_Name",
     where "Name" is the constant value name appearing in XML attributes,
     and "Enum" forms full Pascal type name "T@Enum".
     "E1", ..., "En" are values without "c@Enum_" prefix.

     Attribute types and their XML default values are restricted to the following (note that '#FIXED' decl is not used):

       Integer, Boolean, Color, Enum, EnumSet:
         Cannot be '#IMPLIED', only #REQUIRED or may have a default value.

       Float:
         Must be '#REQUIRED' because Delphi does not allow them a default value.  

       NameList:
         May be only '#IMPLIED' (allow empty list) or '#REQUIRED' (do not allow empty list).

       AnsiString, WideString:
         Must be '#IMPLIED' (Delphi does not support default values for string properties).

     In Delphi, Integer, Boolean, TColor and T@Enum properties may have the 'default XXX' specifier,
     and if they don't, the corresponding XML attribute is assumed to be '#REQUIRED'.
     All string types may NOT have 'default' specifier due to Delphi limitations, and thus are assumed
     to have the default value of empty string, in DTD they are always '#IMPLIED'.

     Element properties may be of object type derived from TXMLObject or TXMLObjectList.
     Their relative order is considered to be the required order of XML elements.
     #PCDATA content is NOT supported.
     Elements and TXMLNameList attributes are considered to be optional if they have 'default nil' storage specifier
     (for lists this doesn't mean a nil list reference but just a possibility of an empty list).

     NOTES:
       It is discouraged though not forbidden to mix attribute and element properties.
       It is possible to define elements as fields, not properties (but then the 'default' specifier cannot be used).
       All lists objects are automatically created in constructor and destroyed in destructor.
       All lists derived from TXMLObjectList have the value OwnsObjects = True.
       All object type properties including lists MUST have 'write' specifier in order to support constructor.
       TColor values may be specified in XML as decimals, hex in Delphi- or C-style, or as color names
         similar to those in Graphics unit (like 'clBlack'), with or without 'cl' prefix (names are generated without
         'cl' prefix when objects are saved to XML).
       TXMLNameList properties SpacedValues and CommaSpacedValues raise EConvertError on assigning a wrong string.

     IMPORTANT:
       Any class derived from TXMLObject should be registered in TXMLObjectRegistry in order to support XML loading.
       {$TYPEINFO ON} compiler directive should appear in unit containing classes derived from TXMLObject.
       Unit name should have the form "@OM", where "@" should be an object model name (OMName).
       All classes from TXMLObject should be named in form "T@Name", where "Name" is the element name.

(*)




implementation


  uses
    Windows, Graphics, TypInfo;


  type
    EXMLOE = EXMLObjectError;



{=======  EXMLObjectError  ============================================================================================}



  const
    sXMLObjectError_PropertyTypeNotSupported =
      'Type of the property is not supported for XML streaming.';
    sXMLObjectError_WrongConstantName =
      'Name of the constant ''%s'' is not supported for XML streaming.';
    sXMLObjectError_WrongAttValue =
      'Attribute value %s is illegal in this context.';
    sXMLObjectError_ElementNotFound =
      'Element ''%s'' expected but not found.';
    sXMLObjectError_WrongElement =
      'Unexpected element ''%s'' found.';
    sXMLObjectError_WrongVersion =
      'Object model version ''%s'' is too low.';
    sXMLObjectError_Unknown =
      'Unknown error';


  constructor EXMLObjectError.Create ( Kind: TXMLObjectError;  const NameOfClass: string = '';
                                       const NameOfProperty: string = '';  const Value: WideString = '' );
  begin
    inherited Create ('');
    FKind := Kind;
    FNameOfClass := NameOfClass;
    FNameOfProperty := NameOfProperty;
    FValue := Value;
    if FNameOfClass <> '' then
      Message := Message + FNameOfClass;
    if FNameOfProperty <> '' then
      Message := Message + '.' + FNameOfProperty;
    if Message <> '' then
      Message := Message + ':  ';
    case FKind of
      cXMLObjectError_PropertyTypeNotSupported:
        Message := Message + sXMLObjectError_PropertyTypeNotSupported;
      cXMLObjectError_WrongConstantName:
        Message := Message + Format(sXMLObjectError_WrongConstantName, [FValue]);
      cXMLObjectError_WrongAttValue:
        Message := Message + Format(sXMLObjectError_WrongAttValue, [QuotedStr(FValue)]);
      cXMLObjectError_ElementNotFound:
        Message := Message + Format(sXMLObjectError_ElementNotFound, [FValue]);
      cXMLObjectError_WrongElement:
        Message := Message + Format(sXMLObjectError_WrongElement, [FValue]);
      cXMLObjectError_WrongVersion:
        Message := Message + Format(sXMLObjectError_WrongVersion, [FValue]);
    else
      Message := Message + sXMLObjectError_Unknown;
    end{case};
  end;





{=======  TXMLObjectList  =============================================================================================}



  function TXMLObjectList.GetIt ( I: Integer ): TXMLObject;
  begin
    Result := List^[I];
  end;



  function TXMLObjectList.Include ( Obj: TXMLObject;  P: Integer = -1 ): TXMLObject;
  begin
    Obj.Owner := Owner;
    Obj.OwnerList := Self;
    if P = -1 then
      Add (Obj)
    else
      Insert(P, Obj);
    Result := Obj;
  end;



  class function TXMLObjectList.ItemClass: TXMLObjectClass;
  begin
    Result := TXMLObject;
  end;



  function TXMLObjectList.XMLString(const LineBreak: WideString;
    Indent: Integer; SpaceAtts, SpaceEqs: Boolean): WideString;
  var
    I: Integer;
  begin
    Result := '';
    for I := 0 to Count-1 do
      Result := Result + It[I].XMLString(LineBreak, Indent, SpaceAtts, SpaceEqs) + LineBreak;
  end;



{=======  TXMLNameList  ===============================================================================================}



  function TXMLNameList.GetSpacedValues: WideString;
  // OPTIMIZE:  Asm, pre-allocate Result
  var
    I: Integer;
  begin
    if FCount = 0 then
    begin
      Result := '';
      Exit;
    end;
    Result := Names[0];
    for I := 1 to FCount-1 do
      Result := Result + ' ' + Names[I];
  end;



  function TXMLNameList.GetCommaSpacedValues: WideString;
  // OPTIMIZE:  Asm, pre-allocate Result
  var
    I: Integer;
  begin
    if FCount = 0 then
    begin
      Result := '';
      Exit;
    end;
    Result := Names[0];
    for I := 1 to FCount-1 do
      Result := Result + ', ' + Names[I];
  end;



  class procedure TXMLNameList.ValidateCommaSpacedValues ( const CommaSpacedValues: WideString );
  var
    I: Integer;
  begin
    I := 1;
    while I <= Length(CommaSpacedValues) do
    begin
      while (CommaSpacedValues[I] <= #32) and (CommaSpacedValues[I] <> #0) do Inc (I);
      while (CommaSpacedValues[I] > #32) and (CommaSpacedValues[I] <> ',') do
        if (Hi(Ord(CommaSpacedValues[I])) <> 0) or (Chr(Lo(Ord(CommaSpacedValues[I]))) in XMLNameCharSet) then
          Inc (I)
        else
          raise EConvertError.Create ('TXMLNameList.SetCommaCommaSpacedValues: ''' + CommaSpacedValues +
                                      ''' is not a valid value.');
      Inc (I);
    end;
  end;



  procedure TXMLNameList.SetSpacedValues ( const SpacedValues: WideString );
  // OPTIMIZE:  Asm will work faster, Str should be allocated incrementally
  var
    I, J: Integer;
  begin
    Names := nil;
    try
      I := 1;
      while I <= Length(SpacedValues) do
      begin
        while (SpacedValues[I] <= #32) and (SpacedValues[I] <> #0) do Inc (I);
        J := I;
        while SpacedValues[J] > #32 do
          if (Hi(Ord(SpacedValues[J])) <> 0) or (Chr(Lo(Ord(SpacedValues[J]))) in XMLNameCharSet) then
            Inc (J)
          else
            raise EConvertError.Create ('TXMLNameList.SetSpacedValues: ''' + SpacedValues + ''' is not a valid value.');
        if J > I then
        begin
          SetLength (Names, Length(Names)+1);
          Names[High(Names)] := Copy (SpacedValues, I, J-I);
        end;
        I := J + 1;
      end;
      FCount := Length(Names);
    except
      Names := nil;
      FCount := 0;
      raise;
    end;
  end;



  procedure TXMLNameList.SetCommaSpacedValues ( const CommaSpacedValues: WideString );
  // OPTIMIZE:  Asm will work faster, Str should be allocated incrementally
  var
    I, J: Integer;
  begin
    Names  := nil;

    try
      I := 1;
      while I <= Length(CommaSpacedValues) do
      begin
        while (CommaSpacedValues[I] <= #32) and (CommaSpacedValues[I] <> #0) do Inc (I);
        J := I;
        while (CommaSpacedValues[J] > #32) and (CommaSpacedValues[J] <> ',') do
          if (Hi(Ord(CommaSpacedValues[J])) <> 0) or (Chr(Lo(Ord(CommaSpacedValues[J]))) in XMLNameCharSet) then
            Inc (J)
          else
            raise EConvertError.Create ('TXMLNameList.SetCommaCommaSpacedValues: ''' + CommaSpacedValues +
                                        ''' is not a valid value.');
        if J > I then
        begin
          SetLength (Names, Length(Names)+1);
          Names[High(Names)] := Copy (CommaSpacedValues, I, J-I);
        end;
        I := J + 1;
      end;
      FCount := Length(Names);
    except
      Names := nil;
      FCount := 0;
      raise;
    end;
  end;



  procedure TXMLNameList.Clear;
  begin
    Names := nil;
  end;



  function TXMLNameList.Add ( const WS: WideString ): Integer;
  var
    Len: Integer;
  begin
    Len := Length(Names);
    if FCount = Len then
      if Len > 64 then
        SetLength (Names, Len + Len div 4)
      else
        if Len > 8 then
          SetLength (Names, Len + 16)
        else
          SetLength (Names, Len + 4);
    Names[FCount] := WS;
    Result := FCount;
    Inc (FCount);
  end;



  procedure TXMLNameList.Insert ( Index: Integer;  const WS: WideString );
  var
    Len: Integer;
  begin
    if (Index < 0) or (Index > FCount) then
      raise EStringListError.Create ('TXMLNameList.Insert:  Index ' + IntToStr(Index) +
                                     ' out of bounds [0..' + IntToStr(FCount-1) + ']');
    Len := Length(Names);
    if FCount = Len then
      if Len > 64 then
        SetLength (Names, Len + Len div 4)
      else
        if Len > 8 then
          SetLength (Names, Len + 16)
        else
          SetLength (Names, Len + 4);
    System.Move (Names[Index], Names[Index+1], (FCount-Index) shl 2);
    Names[Index] := WS;
    Inc (FCount);
  end;



  procedure TXMLNameList.Delete ( Index: Integer );
  begin
    if (Index < 0) or (Index >= FCount) then
      raise EStringListError.Create ('TXMLNameList.Delete:  Index ' + IntToStr(Index) +
                                     ' out of bounds [0..' + IntToStr(FCount-1) + ']');
    Names[Index] := '';
    Dec(FCount);
    if Index < FCount then
      System.Move (Names[Index+1], Names[Index], (FCount - Index) shl 2);
  end;



  procedure TXMLNameList.Move ( CurIndex, NewIndex: Integer );
  var
    P: Pointer;
  begin
    // OPTIMIZE: Only part between indices should be moved
    if (CurIndex < 0) or (CurIndex >= FCount) then
      raise EStringListError.Create ('TXMLNameList.Move:  CurIndex ' + IntToStr(CurIndex) +
                                     ' out of bounds [0..' + IntToStr(FCount-1) + ']');
    if (NewIndex < 0) or (NewIndex >= FCount) then
      raise EStringListError.Create ('TXMLNameList.Move:  NewIndex ' + IntToStr(NewIndex) +
                                     ' out of bounds [0..' + IntToStr(FCount-1) + ']');
    if CurIndex = NewIndex then Exit;
    P := Pointer(Names[CurIndex]);
    if CurIndex < FCount-1 then
      System.Move (Names[CurIndex+1], Names[CurIndex], (FCount-1 - CurIndex) shl 2);
    if NewIndex < FCount-1 then
    System.Move (Names[NewIndex], Names[NewIndex+1], (FCount-1 - NewIndex) shl 2);
    Pointer(Names[NewIndex]) := P;
  end;



  procedure TXMLNameList.Exchange ( Index1, Index2: Integer );
  var
    P: Pointer;
  begin
    if (Index1 < 0) or (Index1 >= FCount) then
      raise EStringListError.Create ('TXMLNameList.Move:  Index1 ' + IntToStr(Index1) +
                                     ' out of bounds [0..' + IntToStr(FCount-1) + ']');
    if (Index2 < 0) or (Index2 >= FCount) then
      raise EStringListError.Create ('TXMLNameList.Move:  Index2 ' + IntToStr(Index2) +
                                     ' out of bounds [0..' + IntToStr(FCount-1) + ']');
    P := Pointer(Names[Index1]);
    Pointer(Names[Index1]) := Pointer(Names[Index2]);
    Pointer(Names[Index2]) := P;
  end;



  function TXMLNameList.IndexOf ( const WS: WideString ): Integer;
  begin
    for Result := 0 to FCount-1 do
      if Names[Result] = WS then Exit;
    Result := -1;
  end;



  procedure TXMLNameList.Assign ( Source: TXMLNameList );
  begin
    Names := Copy (Source.Names);
  end;




{=======  TXMLObject  =================================================================================================}



  const
    cNoDefault: Integer = Integer($80000000);



  procedure TXMLObject.WriteToXMLWriter ( XMLWriter: TXMLWriter );
  var
    PropList:      PPropList;
    PropCount:     Integer;
    PropInfo:      PPropInfo;
    PropClassType: TClass;
    XMLObjectList: TXMLObjectList;
    XMLObject:     TXMLObject;
    XMLNmtokens:   TXMLNameList;
    ElementName:   string;

    I: Integer;
    J: Integer;
    L: Longint;
    S: string;
    C: string;
    W: WideString;
    NL: TXMLNameList;
    E: Extended;

    FormatSettings: TFormatSettings;

  begin
    GetLocaleFormatSettings( GetThreadLocale, FormatSettings );
    FormatSettings.DecimalSeparator := '.';

    ElementName := Copy ( ClassName,  Length(GetTypeData(ClassInfo).UnitName),  MaxInt );
    XMLWriter.StartElement (ElementName);
    PropCount := GetPropList (Self, PropList);
    try

      ///////  Writing attributes:

      for I := 0 to PropCount-1 do
      begin
        PropInfo := PropList[I];
        case PropInfo.PropType^.Kind of

          tkLString:
          begin
            S := GetStrProp(Self, PropInfo);
            if S <> '' then
              XMLWriter.WriteAtt (PropInfo.Name, S);
          end;

          tkWString:
          begin
            W := GetWideStrProp(Self, PropInfo);
            if W <> '' then
              XMLWriter.WriteAtt (PropInfo.Name, W);
          end;

          tkInteger:
          begin
            L := GetOrdProp (Self, PropInfo);
            if (PropInfo.Default = cNoDefault) or (PropInfo.Default <> L) then
            begin
              if PropInfo.PropType^.Name = 'TColor' then
              begin
                C := ColorToString (TColor(L));
                if Copy(C, 1, 2) = 'cl' then
                  C := Copy (C, 3, MaxInt);
              end
              else
                C := GetEnumProp(Self, PropInfo);
              XMLWriter.WriteAtt (PropInfo.Name, C);
            end;
          end;

          tkChar, tkWChar:
          begin
            L := GetOrdProp (Self, PropInfo);
            if L < 32 then
              W := '#' + IntToStr(L)
            else
            begin
              SetLength (W, 1);
              W[1] := WideChar(L);
            end;
            XMLWriter.WriteAtt (PropInfo.Name, W);
          end;

          tkFloat:
          begin
            E := GetFloatProp (Self, PropInfo);
            XMLWriter.WriteAtt (PropInfo.Name, FloatToStr(E, FormatSettings));
          end;

          tkEnumeration:
          begin
            L := GetOrdProp (Self, PropInfo);
            if (PropInfo.Default = cNoDefault) or (PropInfo.Default <> L) then
            begin
              C := GetEnumProp(Self, PropInfo);
              if PropInfo.PropType^ <> TypeInfo(Boolean) then
              begin
                S := PropInfo.PropType^.Name + '_';
                S[1] := 'c';
                C := Copy (C, Length(S)+1, MaxInt);
              end;
              XMLWriter.WriteAtt (PropInfo.Name, C);
            end;
          end;

          tkSet:
          begin
            L := GetOrdProp( Self, PropInfo );
            if (PropInfo.Default = cNoDefault) or (PropInfo.Default <> L) then
            begin
              NL := TXMLNameList.Create;
              try
                NL.CommaSpacedValues := SetToString( PropInfo, L );
                S := GetTypeData(PropInfo.PropType^).CompType^.Name + '_';
                S[1] := 'c';
                for J := 0 to NL.Count-1 do
                  NL.Names[J] := Copy( NL.Names[J], Length(S)+1, MaxInt );
                XMLWriter.WriteAtt( PropInfo.Name, NL.SpacedValues );
              finally
                NL.Free;
              end;
            end;
          end;

          tkClass:
            {NOP};
            
        else{case}
          raise EXMLOE.Create (cXMLObjectError_PropertyTypeNotSupported, ClassName, PropInfo.Name);
        end{case};
      end;


      ///////  Writing elements:

      for I := 0 to PropCount-1 do
      begin
        PropInfo := PropList[I];
        case PropInfo.PropType^.Kind of

          tkLString, tkWString, tkInteger, tkFloat, tkEnumeration, tkSet, tkChar, tkWChar:
            {NOP};

          tkClass:
          begin
            PropClassType := GetTypeData(PropInfo.PropType^).ClassType;
            if PropClassType.InheritsFrom(TXMLObjectList) then
            begin
              XMLObjectList := TXMLObjectList ( GetOrdProp (Self, PropInfo) );
              for J := 0 to XMLObjectList.Count-1 do
                XMLObjectList[J].WriteToXMLWriter (XMLWriter);
            end
            else
              if PropClassType = TXMLNameList then
              begin
                XMLNmtokens := TXMLNameList(GetOrdProp(Self, PropInfo));
                if XMLNmtokens.Count > 0 then
                  XMLWriter.WriteAtt (PropInfo.Name, XMLNmtokens.SpacedValues);
              end
              else
              begin
                XMLObject := TXMLObject ( GetOrdProp (Self, PropInfo) );
                if Assigned(XMLObject) then
                  XMLObject.WriteToXMLWriter (XMLWriter);
              end;
          end;

        else{case}
          raise EXMLOE.Create (cXMLObjectError_PropertyTypeNotSupported, ClassName, PropInfo.Name);
        end{case};
      end;

    finally
      if PropCount > 0 then
        FreeMem (PropList);
    end;

    XMLWriter.FinishElement (ElementName);
  end;




  constructor TXMLObject.CreateFromXMLNode ( XMLNode: TXMLNode;  XMLObjectRegistry: TXMLObjectRegistry );

  const
    NumberStartSet: set of Char = ['0'..'9', '-', '+', '$'];

  var
    PropList:       PPropList;
    PropCount:      Integer;
    PropInfo:       PPropInfo;
    PropClassType:  TClass;
    XMLObjectList:  TXMLObjectList;
    XMLObject:      TXMLObject;
    XMLObjectClass: TXMLObjectClass;
    XMLNmtokens:    TXMLNameList;

    I, J, V: Integer;
    S, C: string;
    W: WideString;
    NL: TXMLNameList;

    FormatSettings: TFormatSettings;

  begin
    Create;
    GetLocaleFormatSettings( GetThreadLocale, FormatSettings );
    FormatSettings.DecimalSeparator := '.';

    PropCount := GetPropList (Self, PropList);
    try
      for I := 0 to PropCount-1 do
      begin
        PropInfo := PropList[I];
        case PropInfo.PropType^.Kind of

          tkLString:
            SetStrProp(Self, PropInfo, XMLNode.Att[PropInfo.Name]);

          tkWString:
            SetWideStrProp(Self, PropInfo, XMLNode.Att[PropInfo.Name]);

          tkInteger:
          begin
            S := XMLNode.Att[PropInfo.Name];
            if PropInfo.PropType^.Name = 'TColor' then
            begin
              if not (S[1] in NumberStartSet) and (Copy(S, 1, 2) <> 'cl') then
                S := 'cl' + S;
              try
                SetOrdProp (Self, PropInfo, StringToColor(S));
              except
                raise EXMLOE.Create (cXMLObjectError_WrongAttValue, ClassName,
                                     PropInfo.Name, XMLNode.Att[PropInfo.Name]);
              end;
            end
            else
              try
                SetOrdProp (Self, PropInfo, StrToInt(S));
              except
                raise EXMLOE.Create (cXMLObjectError_WrongAttValue, ClassName, PropInfo.Name, XMLNode.Att[PropInfo.Name]);
              end;
          end;

          tkChar, tkWChar:
          begin
            W := XMLNode.Att[propInfo.Name];
            if Length(W) = 1 then
              V := Integer(W[1])
            else if Length(W) > 1 then
            begin
              if W[1] <> '#' then
                raise EXMLOE.Create (cXMLObjectError_WrongAttValue, ClassName, PropInfo.Name, W);
              try
                V := StrToInt(Copy(W, 2, MaxInt));
              except
                raise EXMLOE.Create (cXMLObjectError_WrongAttValue, ClassName, PropInfo.Name, W);
              end;
            end
            else
            begin
              raise EXMLOE.Create (cXMLObjectError_WrongAttValue, ClassName, PropInfo.Name, W);
              V := 0; // Warning suppress.
            end;

            try
              SetOrdProp(Self, PropInfo, V)
            except
              raise EXMLOE.Create (cXMLObjectError_WrongAttValue, ClassName, PropInfo.Name, W);
            end;
          end;

          tkFloat:
          begin
            S := XMLNode.Att[PropInfo.Name];
            try
              SetFloatProp (Self, PropInfo, StrToFloat(S, FormatSettings));
            except
              try
                SetFloatProp (Self, PropInfo, StrToFloat(S));  // Try current locale.
              except
                raise EXMLOE.Create (cXMLObjectError_WrongAttValue, ClassName, PropInfo.Name,
                                     XMLNode.Att[PropInfo.Name]);
              end;
            end;
          end;

          tkEnumeration:
          begin
            S := XMLNode.Att[PropInfo.Name];
            if PropInfo.PropType^ <> TypeInfo(Boolean) then
            begin
              S := PropInfo.PropType^.Name + '_' + S;
              S[1] := 'c';
            end;
            try
              SetEnumProp (Self, PropInfo, S);
            except
              raise EXMLOE.Create (cXMLObjectError_WrongAttValue, ClassName, PropInfo.Name, XMLNode.Att[PropInfo.Name]);
            end;
          end;

          tkSet:
          begin
            S := XMLNode.Att[PropInfo.Name];
            NL := TXMLNameList.Create;
            try
              try
                NL.SpacedValues := S;

                C := GetTypeData(PropInfo.PropType^).CompType^.Name + '_';
                C[1] := 'c';

                for J := 0 to NL.Count-1 do
                  NL.Names[J] := C + NL.Names[J];
                SetSetProp( Self, PropInfo, '[' + NL.CommaSpacedValues + ']' );
              except
                raise EXMLOE.Create( cXMLObjectError_WrongAttValue, ClassName, PropInfo.Name, XMLNode.Att[PropInfo.Name] );
              end;
            finally
              NL.Free;
            end;
          end;

          tkClass:
          begin
            PropClassType := GetTypeData(PropInfo.PropType^).ClassType;
            if PropClassType.InheritsFrom(TXMLObjectList) then
            begin
              XMLObjectList := TXMLObjectList ( GetOrdProp (Self, PropInfo) );
              while Assigned(XMLNode.Child) do
              begin
                if XMLNode.Child.Kind = cXMLNodeKind_Element then
                begin
                  XMLObjectClass := XMLObjectRegistry.Find (XMLNode.Child.Name);
                  if Assigned(XMLObjectClass) then
                  begin
                    if not XMLObjectClass.InheritsFrom (XMLObjectList.ItemClass) then Break;
                    XMLObject := XMLObjectClass.CreateFromXMLNode (XMLNode.Child, XMLObjectRegistry);
                    XMLObject.Owner := Self;
                    XMLObject.OwnerList := XMLObjectList;
                    XMLObjectList.Add(XMLObject);
                  end;
                end;
                XMLNode.NextChild;
              end;
              if (PropInfo.Default <> 0) and (XMLObjectList.Count = 0) then
                  raise EXMLOE.Create (cXMLObjectError_ElementNotFound, ClassName, PropInfo.Name,
                                       XMLObjectRegistry.Find (XMLObjectList.ItemClass));
            end
            else
              if PropClassType = TXMLNameList then
              begin
                XMLNmtokens := TXMLNameList ( GetOrdProp (Self, PropInfo) );
                XMLNmtokens.SpacedValues := XMLNode.Att[PropInfo.Name];
                if (PropInfo.Default <> 0) and (XMLNmtokens.Count = 0) then
                  raise EXMLOE.Create (cXMLObjectError_WrongAttValue, ClassName, PropInfo.Name,
                                       XMLNode.Att[PropInfo.Name]);
              end
              else
              begin
                XMLObjectClass := nil;
                while Assigned(XMLNode.Child) do
                begin
                  if XMLNode.Child.Kind = cXMLNodeKind_Element then
                  begin
                    XMLObjectClass := XMLObjectRegistry.Find (XMLNode.Child.Name);
                    if Assigned(XMLObjectClass) then Break;
                  end;
                  XMLNode.NextChild;
                end;
                XMLObject := nil;
                if PropInfo.Default <> 0 then
                  if not Assigned(XMLObjectClass) then
                    raise EXMLOE.Create ( cXMLObjectError_ElementNotFound,  ClassName,  PropInfo.Name,
                                          XMLObjectRegistry.Find(
                                            TXMLObjectClass(GetTypeData(PropInfo.PropType^).ClassType)) )
                  else
                    if not XMLObjectClass.InheritsFrom ( GetTypeData(PropInfo.PropType^).ClassType ) then
                      raise EXMLOE.Create (cXMLObjectError_WrongElement, ClassName, PropInfo.Name, XMLNode.Child.Name)
                    else
                    begin
                      XMLObject := XMLObjectClass.CreateFromXMLNode (XMLNode.Child, XMLObjectRegistry);
                      XMLNode.NextChild;
                    end
                else
                  if Assigned(XMLObjectClass) and
                     XMLObjectClass.InheritsFrom ( GetTypeData(PropInfo.PropType^).ClassType ) then
                  begin
                    XMLObject := XMLObjectClass.CreateFromXMLNode (XMLNode.Child, XMLObjectRegistry);
                    XMLNode.NextChild;
                  end;
                if Assigned(XMLObject) then
                  XMLObject.Owner := Self;
                SetOrdProp (Self, PropInfo, Integer(XMLObject));
              end;
          end;

        else{case}
          raise EXMLOE.Create (cXMLObjectError_PropertyTypeNotSupported, ClassName, PropInfo.Name);
        end{case};
      end;
    finally
      if PropCount > 0 then
        FreeMem (PropList);
    end;
  end;



  constructor TXMLObject.Create;
  var
    PropList: PPropList;
    PropCount: Integer;
    PropInfo: PPropInfo;
    PropClassType: TClass;
    I: Integer;
    XMLObjectList: TXMLObjectList;
  begin
    PropCount := GetPropList (Self, PropList);
    try
      for I := 0 to PropCount-1 do
      begin
        PropInfo := PropList[I];
        case PropInfo.PropType^.Kind of

          tkClass:
          begin
            PropClassType := GetTypeData(PropInfo.PropType^).ClassType;

            if PropClassType.InheritsFrom(TXMLObjectList) then
            begin
              XMLObjectList := TXMLObjectListClass(PropClassType).Create;
              XMLObjectList.Owner := Self;
              SetOrdProp (Self, PropInfo, Integer(XMLObjectList));
            end
            else
              if PropClassType = TXMLNameList then
                SetOrdProp (Self, PropInfo, Integer(TXMLNameList.Create));
          end;

          tkEnumeration, tkSet, tkInteger, tkChar, tkWChar:
            if PropInfo.Default <> cNoDefault then
              SetOrdProp (Self, PropInfo, PropInfo.Default);

        end{case};
      end;
    finally
      if PropCount > 0 then
        FreeMem (PropList);
    end;
  end;



  destructor TXMLObject.Destroy;
  var
    PropList: PPropList;
    PropCount: Integer;
    PropInfo: PPropInfo;
    I: Integer;
  begin
    if Assigned (OnDestroy) then OnDestroy (Self);
    ExtraObj.Free;
    if Assigned (ExtraPtr) then Dispose (ExtraPtr);
    PropCount := GetPropList (Self, PropList);
    try
      for I := 0 to PropCount-1 do
      begin
        PropInfo := PropList[I];
        if PropInfo.PropType^.Kind = tkClass then
          TObject(GetOrdProp(Self, PropInfo)).Free;
      end;
    finally
      if PropCount > 0 then
        FreeMem (PropList);
    end;
  end;



  function TXMLObject.Clone: TXMLObject;
  var
    PropList: PPropList;
    PropCount: Integer;
    PropInfo: PPropInfo;
    PropClassType: TClass;
    XMLObjectList, NewXMLObjectList: TXMLObjectList;
    XMLNmtokens, NewXMLNmtokens: TXMLNameList;
    XMLObject: TXMLObject;
    I, J: Integer;
  begin
    Result := TXMLObjectClass(ClassType).Create;

    try
      PropCount := GetPropList (Self, PropList);
      try
        for I := 0 to PropCount-1 do
        begin
          PropInfo := PropList[I];
          case PropInfo.PropType^.Kind of

            tkLString:
              SetStrProp (Result, PropInfo, GetStrProp(Self, PropInfo));

            tkWString:
              SetWideStrProp (Result, PropInfo, GetWideStrProp(Self, PropInfo));

            tkEnumeration, tkInteger, tkSet, tkChar, tkWChar:
              SetOrdProp (Result, PropInfo, GetOrdProp(Self, PropInfo));

            tkFloat:
              SetFloatProp (Result, PropInfo, GetFloatProp(Self, PropInfo));

            tkClass:
            begin
              PropClassType := GetTypeData(PropInfo.PropType^).ClassType;
              if PropClassType.InheritsFrom(TXMLObjectList) then
              begin
                XMLObjectList := TXMLObjectList ( GetOrdProp(Self, PropInfo) );
                NewXMLObjectList := TXMLObjectList ( GetOrdProp(Result, PropInfo) );
                NewXMLObjectList.Capacity := XMLObjectList.Count;
                NewXMLObjectList.Owner := Result;
                for J := 0 to XMLObjectList.Count-1 do
                  NewXMLObjectList.Include (XMLObjectList[J].Clone);
              end
              else
                if PropClassType = TXMLNameList then
                begin
                  XMLNmtokens := TXMLNameList ( GetOrdProp(Self, PropInfo) );
                  NewXMLNmtokens := TXMLNameList ( GetOrdProp(Result, PropInfo) );
                  NewXMLNmtokens.Assign(XMLNmtokens);
                end
                else
                begin
                  XMLObject := TXMLObject ( GetOrdProp(Self, PropInfo) );
                  if Assigned(XMLObject) then
                  begin
                    XMLObject := XMLObject.Clone;
                    XMLObject.Owner := Result;
                  end;
                  SetOrdProp (Result, PropInfo, Integer(XMLObject));
                end;
            end;

          end{case};

        end;
      finally
        if PropCount > 0 then
          FreeMem (PropList);
      end;
    except
      Result.Free;
      raise;
    end;
  end;



  function TXMLObject.Remove: TXMLObject;
  begin
    if Assigned(OwnerList) then
      OwnerList.Extract (Self);
    Result := Self;
  end;



  function TXMLObject.ReplaceWith ( XMLObject: TXMLObject ): {XMLObject}TXMLObject;
  begin
    Result := XMLObject;
    if Assigned(OwnerList) then
      OwnerList.List^[OwnerList.IndexOf(Self)] := XMLObject;
    XMLObject.Remove;
    XMLObject.OwnerList := OwnerList;
    XMLObject.Owner := Owner;
    OwnerList := nil;
    Owner := nil;
  end;



  constructor TXMLObject.CreateFromXMLStream ( Stream: TStream;  XMLObjectRegistry: TXMLObjectRegistry );
  var
    Root: TXMLNode;
    Version: string;
  begin
    XMLObjectRegistry.XMLParser.StartParsing (Stream);
    Root := XMLObjectRegistry.XMLParser.Root;

    while Assigned(Root.Child) and (Root.Child.Kind <> cXMLNodeKind_Element) do Root.NextChild;
    if not Assigned(Root.Child) then
      raise EXMLOE.Create (cXMLObjectError_ElementNotFound, '', '', XMLObjectRegistry.OMName);
    if Root.Child.Name <> XMLObjectRegistry.OMName then
      raise EXMLOE.Create (cXMLObjectError_WrongElement, '', '', Root.Child.Name);
    Version := Root.Child.Att['version'];
    if (Version <> '') and (Version < XMLObjectRegistry.ReadsVersion) then
      raise EXMLOE.Create (cXMLObjectError_WrongVersion, '', '', Version);

    while Assigned(Root.Child.Child) and (Root.Child.Child.Kind <> cXMLNodeKind_Element) do Root.Child.NextChild;
    if not Assigned(Root.Child.Child) then
      raise EXMLOE.Create (cXMLObjectError_ElementNotFound, '', '', XMLObjectRegistry.Find(TXMLObjectClass(ClassType)));

    CreateFromXMLNode (Root.Child.Child, XMLObjectRegistry);

    Root.Child.NextChild;
    XMLObjectRegistry.XMLParser.StopParsing;
  end;



  function TXMLObject.GetIndex: Integer;

  begin
    Assert(Assigned(OwnerList));
    Result := OwnerList.IndexOf(Self);
  end;



  function TXMLObject.Next(Index: Integer = -1): TXMLObject;

  begin
    Assert(Assigned(OwnerList));

    if Index = -1 then
      Index := OwnerList.IndexOf(Self);
    Assert(Index >= 0);

    if Index + 1 < OwnerList.Count then
      Result := OwnerList.List[Index + 1]
    else
      Result := nil;
  end;



  function TXMLObject.Prev(Index: Integer = -1): TXMLObject;

  begin
    Assert(Assigned(OwnerList));

    if Index = -1 then
      Index := OwnerList.IndexOf(Self);
    Assert(Index >= 0);

    if Index - 1 >= 0 then
      Result := OwnerList.List[Index - 1]
    else
      Result := nil;
  end;



  function TXMLObject.XMLString ( const LineBreak: WideString = #13#10;  Indent: Integer = 0;
                                  SpaceAtts: Boolean = False;  SpaceEqs: Boolean = False ): WideString;
  var
    MS: TMemoryStream;
    XMLWriter: TXMLWriter;
  begin
    MS := TMemoryStream.Create;
    try
      XMLWriter := TXMLWriter.Create (MS, cXMLEncoding_UTF16LE, {WriteBOM}False, LineBreak, {UseIndents}True, Indent,
                                      SpaceAtts, SpaceEqs);
      try
        WriteToXMLWriter (XMLWriter);
      finally
        XMLWriter.Free;
      end;
      SetLength (Result, MS.Size div 2);
      Move (MS.Memory^, Result[1], MS.Size);
    finally
      MS.Free;
    end;
  end;



  procedure TXMLObject.SaveToXMLStream ( Stream: TStream;  const Version: string = '';  const Description: string = '';
                                         Encoding: TXMLEncoding = cXMLEncoding_UTF16LE;
                                         const LineBreak: WideString = #13#10;  UseIndents: Boolean = True;
                                         SpaceAtts: Boolean = False;  SpaceEqs: Boolean = False );
  var
    XMLWriter: TXMLWriter;
    RootElementName: string;

  begin
    RootElementName := GetTypeData(ClassInfo).UnitName;

    XMLWriter := TXMLWriter.Create (Stream, Encoding, {WriteBOM}True, LineBreak, UseIndents, {Indent}0,
                                    SpaceAtts, SpaceEqs);
    with XMLWriter do
      try
        WriteXMLDecl ({Version}'1.0');
        WriteNewLine;
        StartElement (RootElementName);
        if Version <> '' then
          WriteAtt ('version', Version);
        if Description <> '' then
          WriteAtt ('description', Description);
        WriteNewLine;
        WriteToXMLWriter (XMLWriter);
        WriteNewLine;
        FinishElement (RootElementName);
      finally
        XMLWriter.Free;
      end;
  end;




{=======  TXMLObjectRegistry  =========================================================================================}



  constructor TXMLObjectRegistry.Create ( const ReadsVersion: string );
  begin
    inherited Create;
    FList := TStringList.Create;
    FList.CaseSensitive := True;
    FList.Sorted := True;
    FList.Duplicates := dupError;
    FOrderedList := TStringList.Create;
    FOrderedList.CaseSensitive := True;
    FReadsVersion := ReadsVersion;
    FXMLParser := TXMLParser.Create;
  end;



  destructor TXMLObjectRegistry.Destroy;
  begin
    FList.Free;
    FOrderedList.Free;
    FXMLParser.Free;
    inherited Destroy;
  end;



  procedure TXMLObjectRegistry.Register ( XMLObjectClass: TXMLObjectClass );
  var
    ElementName: string;
    PropInfo: PPropInfo;
    PropList: PPropList;
    PropCount: Integer;
    I, J: Integer;
    C: string;
    S: string;
    NL: TXMLNameList;

  begin
    if FOMName = '' then
      FOMName := GetTypeData(XMLObjectClass.ClassInfo).UnitName;
    ElementName := Copy ( XMLObjectClass.ClassName,  Length(FOMName),  MaxInt );
    FList.AddObject (ElementName, TObject(XMLObjectClass));
    FOrderedList.AddObject (ElementName, TObject(XMLObjectClass));

    PropCount := GetPropList (XMLObjectClass.ClassInfo, PropList);
    try
      for I := 0 to PropCount-1 do
      begin
        PropInfo := PropList[I];
        case PropInfo.PropType^.Kind of

          tkString, tkLString, tkWString:
            FXMLParser.RegisterAtt (ElementName, PropInfo.Name, '');

          tkInteger:
            if PropInfo.Default = cNoDefault then
              FXMLParser.RegisterAtt (ElementName, PropInfo.Name, '')
            else
              FXMLParser.RegisterAtt (ElementName, PropInfo.Name, IntToStr(PropInfo.Default));

          tkChar, tkWChar:
            if PropInfo.Default = cNoDefault then
              FXMLParser.RegisterAtt (ElementName, PropInfo.Name, '')
            else
            begin
              if PropInfo.Default > 32 then
                FXMLParser.RegisterAtt (ElementName, PropInfo.Name, WideChar(PropInfo.Default))
              else
                FXMLParser.RegisterAtt (ElementName, PropInfo.Name, '#' + IntToStr(PropInfo.Default));
            end;

          tkFloat:
            FXMLParser.RegisterAtt (ElementName, PropInfo.Name, '');  // Float properties cannot have a default value.

          tkEnumeration:
          begin

            // ATTENTION: Name check must be performed here!

            if PropInfo.Default = cNoDefault then
              FXMLParser.RegisterAtt (ElementName, PropInfo.Name, '')
            else
              if PropInfo.PropType^ = TypeInfo(Boolean) then
                FXMLParser.RegisterAtt (ElementName, PropInfo.Name, BooleanIdents[Boolean(PropInfo.Default)])
              else
              begin
                C := GetEnumName(PropInfo.PropType^, PropInfo.Default);
                S := PropInfo.PropType^.Name + '_';
                S[1] := 'c';
                C := Copy (C, Length(S)+1, MaxInt);
                FXMLParser.RegisterAtt (ElementName, PropInfo.Name, C);
              end;
          end;

          tkSet:
          begin

            // ATTENTION: Name check must be performed here!

            if PropInfo.Default = cNoDefault then
              FXMLParser.RegisterAtt( ElementName, PropInfo.Name, '' )
            else
            begin
              NL := TXMLNameList.Create;
              try
                NL.CommaSpacedValues := SetToString( PropInfo, PropInfo.Default );
                S := GetTypeData(PropInfo.PropType^).CompType^.Name + '_';
                S[1] := 'c';
                for J := 0 to NL.Count-1 do
                  NL.Names[J] := Copy (NL.Names[J], Length(S)+1, MaxInt);
                FXMLParser.RegisterAtt (ElementName, PropInfo.Name, NL.SpacedValues);
              finally
                NL.Free;
              end;
            end;
          end;

          tkClass:
            if GetTypeData(PropInfo.PropType^).ClassType = TXMLNameList then
              FXMLParser.RegisterAtt (ElementName, PropInfo.Name, '');

        else{case}
          raise EXMLOE.Create (cXMLObjectError_PropertyTypeNotSupported, XMLObjectClass.ClassName, PropInfo.Name);
        end{case};
      end;
    finally
      if PropCount > 0 then
        FreeMem (PropList);
    end;
  end;




  function TXMLObjectRegistry.Find ( const XMLElementName: string ): TXMLObjectClass;
  var
    Index: Integer;
  begin
    if FList.Find (XMLElementName, Index) then
      Result := TXMLObjectClass(FList.Objects[Index])
    else
      Result := nil;
  end;



  function TXMLObjectRegistry.Find ( XMLObjectClass: TXMLObjectClass ): string;
  var
    I: Integer;
  begin
    for I := 0 to FList.Count-1 do
      if FList.Objects[I] = TObject(XMLObjectClass) then
      begin
        Result := FList[I];
        Exit;
      end;
    Result := '';
  end;



  function TXMLObjectRegistry.MakeDTD ( Root: TXMLObjectClass;
                                        const Version: string = '';  const Description: string = '';
                                        const LineBreak: string = #13#10 ): string;
  const
    TypeNameLen = 14;
    PropNameLen = 12;

  var
    Content:   string;
    AttList:   string;
    Header:    string;
    Enums:     string;
    EnumsList: TStringList;
    FoundIndex: Integer;
    PropList:  PPropList;
    PropCount: Integer;
    PropInfo:  PPropInfo;
    PropClassType: TClass;
    I: Integer;
    J: Integer;
    K: Integer;
    S: string;
    C: string;
    NL: TXMLNameList;

  begin
    Result := '';
    if FOrderedList.Count = 0 then Exit;

    Header := '  <!ELEMENT ' + FOMName + '  (' + Find(Root) + ') >' + LineBreak +
              '  <!ATTLIST ' + FOMName + LineBreak +
              '    version     CDATA  "' + Version + '"' + LineBreak +
              '    description CDATA  "' + Description + '"' + LineBreak +
              '  >' + LineBreak + LineBreak +
              '  <!ENTITY % Boolean-        "(False | True)" >' + LineBreak +
              '  <!ENTITY % Integer-        "CDATA"          >' + LineBreak +
              '  <!ENTITY % Float-          "CDATA"          >' + LineBreak +
              '  <!ENTITY % AnsiString-     "CDATA #IMPLIED" >' + LineBreak +
              '  <!ENTITY % WideString-     "CDATA #IMPLIED" >' + LineBreak +
              '  <!ENTITY % NameList-       "NMTOKENS"       >' + LineBreak +
              '  <!ENTITY % Color-          "CDATA"          >' + LineBreak +
              LineBreak;

    Enums := '';
    EnumsList := TStringList.Create;
    try
      EnumsList.Sorted := True;
      for J := 0 to FOrderedList.Count-1 do
      begin
        Content := '';
        AttList := '';
        PropCount := GetPropList (TClass(FOrderedList.Objects[J]).ClassInfo, PropList);
        try
          for I := 0 to PropCount-1 do
          begin
            PropInfo := PropList[I];
            case PropInfo.PropType^.Kind of

              tkLString:
                AttList := AttList + '    ' + PropInfo.Name + StringOfChar(' ', PropNameLen-Length(PropInfo.Name)) +
                           '  %AnsiString-;' + LineBreak;

              tkWString:
                AttList := AttList + '    ' + PropInfo.Name + StringOfChar(' ', PropNameLen-Length(PropInfo.Name)) +
                           '  %WideString-;' + LineBreak;

              tkInteger:
              begin
                if PropInfo.PropType^.Name = 'TColor' then
                  C := 'Color'
                else
                  C := 'Integer';
                if PropInfo.Default = cNoDefault then
                  AttList := AttList + '    ' + PropInfo.Name + StringOfChar(' ', PropNameLen-Length(PropInfo.Name)) +
                             '  %'+C+'-;' + StringOfChar(' ', TypeNameLen-Length('%'+C+'-;')) +
                             '  #REQUIRED' + LineBreak
                else
                begin
                  if PropInfo.PropType^.Name = 'TColor' then
                  begin
                    S := ColorToString (TColor(PropInfo.Default));
                    if Copy(S, 1, 2) = 'cl' then
                      S := Copy (S, 3, MaxInt);
                  end
                  else
                    S := IntToStr(PropInfo.Default);

                  AttList := AttList + '    ' + PropInfo.Name + StringOfChar(' ', PropNameLen-Length(PropInfo.Name)) +
                             '  %'+C+'-;' + StringOfChar(' ', TypeNameLen-Length('%'+C+'-;')) +
                             '  "' + S + '"' + LineBreak;
                end;
              end;

              tkChar:
                AttList := AttList + '    ' + PropInfo.Name + StringOfChar(' ', PropNameLen-Length(PropInfo.Name)) +
                           '  %AnsiChar-;' + LineBreak;

              tkWChar:
                AttList := AttList + '    ' + PropInfo.Name + StringOfChar(' ', PropNameLen-Length(PropInfo.Name)) +
                           '  %WideChar-;' + LineBreak;

              tkFloat:
                AttList := AttList + '    ' + PropInfo.Name + StringOfChar(' ', PropNameLen-Length(PropInfo.Name)) +
                           '  %Float-;' + LineBreak;

              tkEnumeration:
              begin
                if (PropInfo.PropType^ <> TypeInfo(Boolean)) and
                   not EnumsList.Find(PropInfo.PropType^.Name, FoundIndex) then
                begin
                  EnumsList.Add (PropInfo.PropType^.Name);
                  Enums := Enums + '  <!ENTITY % ' + Copy (PropInfo.PropType^.Name, Length(FOMName), MaxInt) + '  "(';
                  for K := GetTypeData(PropInfo.PropType^).MinValue to GetTypeData(PropInfo.PropType^).MaxValue do
                  begin
                    C := GetEnumName(PropInfo.PropType^, K);
                    S := PropInfo.PropType^.Name + '_';
                    S[1] := 'c';
                    C := Copy (C, Length(S)+1, MaxInt);
                    Enums := Enums + C + ' | ';
                  end;
                  Enums[Length(Enums)-2] := ')';
                  Enums[Length(Enums)-1] := '"';
                  Enums[Length(Enums)-0] := ' ';
                  Enums := Enums + '>' + LineBreak;
                end;

                AttList := AttList + '    ' + PropInfo.Name + StringOfChar(' ', PropNameLen-Length(PropInfo.Name));
                if PropInfo.PropType^ = TypeInfo(Boolean) then
                  S := '%Boolean-;'
                else
                  S := '%' + Copy (PropInfo.PropType^.Name, Length(FOMName), MaxInt) + ';';
                AttList := AttList + '  ' + S + StringOfChar(' ', TypeNameLen-Length(S));
                if PropInfo.Default = cNoDefault then
                  AttList := AttList + '  #REQUIRED' + LineBreak
                else
                  if PropInfo.PropType^ = TypeInfo(Boolean) then
                    AttList := AttList + '  "' + BooleanIdents[Boolean(PropInfo.Default)] + '"' + LineBreak
                  else
                  begin
                    C := GetEnumName(PropInfo.PropType^, PropInfo.Default);
                    S := PropInfo.PropType^.Name + '_';
                    S[1] := 'c';
                    if Copy(C, 1, Length(S)) = S then
                      C := Copy (C, Length(S)+1, MaxInt);
                    AttList := AttList + '  "' + C + '"' + LineBreak;
                  end;
              end;

              tkSet:
              begin
                if not EnumsList.Find( PropInfo.PropType^.Name, FoundIndex ) then
                begin
                  EnumsList.Add (PropInfo.PropType^.Name);
                  Enums := Enums + '  <!ENTITY % ' + Copy (PropInfo.PropType^.Name, Length(FOMName), MaxInt) +
                           '  "NMTOKENS">' + LineBreak;
                end;

                AttList := AttList + '    ' + PropInfo.Name + StringOfChar(' ', PropNameLen-Length(PropInfo.Name));
                S := '%' + Copy (PropInfo.PropType^.Name, Length(FOMName), MaxInt) + ';';
                AttList := AttList + '  ' + S + StringOfChar(' ', TypeNameLen-Length(S));
                if PropInfo.Default = cNoDefault then
                  AttList := AttList + '  #REQUIRED' + LineBreak
                else
                begin
                  S := GetTypeData(PropInfo.PropType^).CompType^.Name + '_';
                  S[1] := 'c';
                  NL := TXMLNameList.Create;
                  try
                    NL.CommaSpacedValues := SetToString( PropInfo, PropInfo.Default );
                    for K := 0 to NL.Count-1 do
                      NL.Names[K] := Copy( NL.Names[K], Length(S)+1, MaxInt );
                    AttList := AttList + '  "' + NL.SpacedValues + '"' + LineBreak;
                  finally
                    NL.Free;
                  end;
                end;
              end;

              tkClass:
              begin
                PropClassType := GetTypeData(PropInfo.PropType^).ClassType;

                if PropClassType.InheritsFrom(TXMLObjectList) then
                begin
                  Content := Content + ', ' + Find(TXMLObjectListClass(PropClassType).ItemClass);
                  if PropInfo.Default = 0 then
                    Content := Content + '*'
                  else
                    Content := Content + '+';
                end
                else
                  if PropClassType = TXMLNameList then
                  begin
                    AttList := AttList + '    ' + PropInfo.Name + StringOfChar(' ', PropNameLen-Length(PropInfo.Name)) +
                               '  %NameList-;' + StringOfChar (' ', TypeNameLen-Length('%NameList-;'));
                    if PropInfo.Default = 0 then
                      AttList := AttList + '  #IMPLIED' + LineBreak
                    else
                      AttList := AttList + '  #REQUIRED' + LineBreak;
                  end
                  else
                  begin
                    Content := Content + ', ' + Find(TXMLObjectClass(PropClassType));
                    if PropInfo.Default = 0 then
                      Content := Content + '?';
                  end;
              end;

            else{case}
              raise EXMLOE.Create (cXMLObjectError_PropertyTypeNotSupported,
                                   TClass(FOrderedList.Objects[J]).ClassName, PropInfo.Name);
            end{case};
          end;
        finally
          if PropCount > 0 then
            FreeMem (PropList);
        end;
        if Content = '' then
          Content := 'EMPTY'
        else
          Content := '(' + Copy (Content, 3, MaxInt) + ')';
        Result := Result + '  <!ELEMENT ' + FOrderedList[J] + '  ' + Content + ' >' + LineBreak +
          '  <!ATTLIST ' + FOrderedList[J] + LineBreak + AttList + '  >' + LineBreak + LineBreak;

      end;
    finally
      EnumsList.Free;
    end;

    if Enums <> '' then
      Enums := Enums + LineBreak;

    Result := Header + Enums + LineBreak + Result;
  end;

{======= TXMLNamedObjectList ==========================================================================================}

  procedure TXMLNamedObjectList.CheckDuplicates;
  var
    I: Integer;
    Item: TXMLNamedObject;
  begin
    for I := 0 to Count-1 do
    begin
      Item := TXMLNamedObject(List[I]);
      if FindByName(Item.Name, Item ) <> nil then
        raise EDuplicateError.Create( Item.Name );
    end;
  end;



  function TXMLNamedObjectList.FindByName(const Name: WideString;
    Exclude: TXMLNamedObject): TXMLNamedObject;
  var
    I: Integer;
  begin
    for I := 0 to Count-1 do
    begin
      Result := TXMLNamedObject(List[I]);
      if (Result <> Exclude) and (Result.Name = Name) then Exit;
    end;
    Result := nil;
  end;



{======= EDuplicateError ==============================================================================================}

  resourcestring
    sDuplicateError_NameDuplicated
      = 'Name ''%s'' dublicated in the list.';

  constructor EDuplicateError.Create(const Name: WideString);
  begin
    inherited CreateResFmt(@sDuplicateError_NameDuplicated, [QuotedStr(Name)]);
    FName := Name;
  end;


end.
