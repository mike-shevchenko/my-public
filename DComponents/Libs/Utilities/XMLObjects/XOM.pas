unit XOM;

{$TYPEINFO ON}

interface


  uses
    Classes, Graphics,
    XMLObjects, XMLWriters;



  const
    Version      = '1.0';
    ReadsVersion = '0.0';
    Description  = 'X test Object Model';



  function MakeDTD ( const LineBreak: string = #13#10 ): string;



  type

    TXEnum = ( cXEnum_E0, cXEnum_E1,  cXEnum_E2 );

    TXEnumSet = set of TXEnum;

    TXObj = class;



    TXObjList = class ( TXMLObjectList )  private function GetIt ( I: Integer ): TXObj;  public
      class function ItemClass: TXMLObjectClass;  override;
      property It [ I: Integer ]: TXObj  read GetIt;  default;
      function Include ( Obj: TXObj;  P: Integer = -1 ): TXObj;
    end;



    TXObj = class ( TXMLObject )
    private
      FInt:  Integer;
      FStr:  string;
      FWStr: WideString;
      FBool: Boolean;
      FList: TXMLNameList;
      FEnum: TXEnum;
      FEnumSet: TXEnumSet;
      FColor: TColor;

      FXObj: TXObj;
      FXObjs: TXObjList;
      FXObjs2: TXObjList;

    published
      property Int:  Integer     read FInt   write FInt   default 1;
      property Str:  string      read FStr   write FStr;
      property WStr: WideString  read FWStr  write FWStr;
      property Bool: Boolean     read FBool  write FBool  default True;
      property List: TXMLNameList read FList  write FList  default nil;
      property Enum: TXEnum   read FEnum  write FEnum  default cXEnum_E0;
      property EnumSet: TXEnumSet  read FEnumSet  write FEnumSet  default [cXEnum_E2];
      property Color: TColor  read FColor  write FColor;

      property X:  TXObj      read FXObj   write FXObj   default nil;
      property Xs: TXObjList  read FXObjs  write FXObjs  default nil;
      property Xs2:TXObjList  read FXObjs2 write FXObjs2 default nil;
    end;



    TXObj2 = class ( TXMLObject )
    private
      FInt:  Integer;
      FStr:  string;
      FWStr: WideString;
      FBool: Boolean;
      FList: TXMLNameList;
      FEnum: TXEnum;

      FXObj: TXObj;
      FXObjs2: TXObjList;

    published
      property Int:  Integer     read FInt   write FInt   default $FFFF;
      property Str:  string      read FStr   write FStr;
      property WStr: WideString  read FWStr  write FWStr;
      property Bool: Boolean     read FBool  write FBool  default False;
      property List: TXMLNameList read FList  write FList  default nil;
      property Enum: TXEnum   read FEnum  write FEnum  default cXEnum_E0;

      property X:  TXObj      read FXObj   write FXObj   default nil;
      property Xs2:TXObjList  read FXObjs2 write FXObjs2;

    public
      constructor CreateFromXMLStream ( Stream: TStream );
      procedure   SaveToXMLStream     ( Stream: TStream;  Encoding: TXMLEncoding = cXMLEncoding_UTF16LE;
                                        const LineBreak: WideString = #13#10;  UseIndents: Boolean = True;
                                        SpaceAtts: Boolean = False;  SpaceEqs: Boolean = False );
    end;




implementation



  class function TXObjList.ItemClass: TXMLObjectClass;  begin  Result := TXObj  end;
  function TXObjList.GetIt ( I: Integer ): TXObj;  begin  Result := List^[I]  end;
  function TXObjList.Include ( Obj: TXObj;  P: Integer = -1 ): TXObj;
    begin Obj.Owner := Owner; Obj.OwnerList := Self; if P = -1 then Add(Obj) else Insert(P, Obj); Result := Obj; end;



  var
    XMLObjectRegistry: TXMLObjectRegistry;




  function MakeDTD ( const LineBreak: string = #13#10 ): string;
  begin
    Result := XMLObjectRegistry.MakeDTD (TXObj2, Version, Description, LineBreak);
  end;



  constructor TXObj2.CreateFromXMLStream ( Stream: TStream );
  begin
    inherited CreateFromXMLStream (Stream, XMLObjectRegistry);
  end;



  procedure TXObj2.SaveToXMLStream ( Stream: TStream;  Encoding: TXMLEncoding = cXMLEncoding_UTF16LE;
                                     const LineBreak: WideString = #13#10;  UseIndents: Boolean = True;
                                     SpaceAtts: Boolean = False;  SpaceEqs: Boolean = False );
  begin
    inherited SaveToXMLStream (Stream, Version, Description, Encoding, LineBreak, UseIndents, SpaceAtts, SpaceEqs);
  end;



initialization



  XMLObjectRegistry := TXMLObjectRegistry.Create (ReadsVersion);

  with XMLObjectRegistry do
  begin
    Register (TXObj);
    Register (TXObj2);
  end;

  

finalization

  XMLObjectRegistry.Free;

end.

