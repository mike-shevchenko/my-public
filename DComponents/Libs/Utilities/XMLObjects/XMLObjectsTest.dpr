program XMLObjectsX;

{$APPTYPE CONSOLE}


uses
  SysUtils,
  Classes,
  XMLObjects,
  XMLParsers,
  XMLWriters,
  XOM in 'XOM.pas';




var
  XObj2: TXObj2;
  FS: TFileStream;
  DTD: string;


begin

  try
    XObj2 := TXObj2.Create;
    try
      with XObj2 do
      begin
        Int := $FFFF;
        Str := 'Str2';
        WStr := 'WStr2';
        Bool := False;
        List.Add ('S2_1');
        List.Add ('S2_2');
        Enum := cXEnum_E1;
        X := TXObj.Create;
        X.Str := 'Inner 2';
        X.Color := 0;
        X.EnumSet := [cXEnum_E0, cXEnum_E2];
        Xs2.Include(TXObj.Create).Str := 'Inner 2 _ 1';
        Xs2[0].Xs.Include(TXObj.Create).Str := 'Inner 2 _ 2';
      end;

      FS := TFileStream.Create ('X.xml', fmCreate);
      try
        XObj2.SaveToXMLStream (FS, {cXMLEncoding_UTF16LE} cXMLEncoding_Windows1251, #13#10);
      finally
        FS.Free;
      end;

      Writeln (XObj2.XMLString);

    finally
      XObj2.Free;
    end;



    FS := TFileStream.Create ('X.xml', fmOpenRead);
    try
      XObj2 := TXObj2.CreateFromXMLStream (FS);
    finally
      FS.Free;
    end;

    try
      Writeln (XObj2.XMLString);
    finally
      XObj2.Free;
    end;


    DTD := XOM.MakeDTD;
    FS := TFileStream.Create ('X.dtd', fmCreate);
    try
      FS.WriteBuffer (DTD[1], Length(DTD));
    finally
      FS.Free;
    end;

  except
    Writeln (ExceptObject.ClassName + ': "' + Exception(ExceptObject).Message + '".');
  end;

  Write ('Press ENTER to exit...');
  Readln;

end.


