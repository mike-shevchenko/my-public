
program Map64Test;

{$APPTYPE CONSOLE}


uses
  Map64 in '..\Map64.pas';

var
  Key, Value: Longword;
  Found: Boolean;
  Map: array [0..7] of record Key, Value: Longword end;
  I: Integer;


begin

  Writeln ('Map before sort:');

  for I := 0 to High(Map) do
  begin
    Map[I].Key := Length(Map)-I;
    Map[I].Value := I*100;
    Writeln ('(', Map[I].Key:2, ', ', Map[I].Value:3, ')');
  end;

  SortMap64 (@Map[0], Length(Map));

  Writeln ('Map after sort:');

  for I := 0 to High(Map) do
    Writeln ('(', Map[I].Key:2, ', ', Map[I].Value:3, ')');

  Writeln ('Enter a Key to find or 0 to exit.');

  repeat

    Write ('(');
    Read (Key);
    if Key = 0 then Break;
    Write (', ');

    Found := FindInMap64 (@Map[0], Length(Map), Key, Value);

    if Found then
      Writeln (Value, ')')
    else
      Writeln ('NOT_FOUND)');

  until False;

end.
