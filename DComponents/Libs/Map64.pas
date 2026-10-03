unit Map64;


interface


  // Description:
  {
    Map is an array of 64-bit pairs of 32-bit Key and Value.
    This unit provides sort and binary search features for such arrays.
  }


  procedure SortMap64   ( MapPtr: Pointer;  Count: Integer );

  function  FindInMap64 ( MapPtr: Pointer;  Count: Integer;  const Key;  out Value ): {Found}Boolean;



implementation



  type
    TMapRec = record  Key, Value: Longword  end;
    PMapRecArray = ^TMapRecArray;
    TMapRecArray = array [0..0] of TMapRec;




  procedure SortMap64 ( MapPtr: Pointer;  Count: Integer );

  var
    I: Integer;
    Temp: TMapRec;

  begin
    if Count <= 1 then Exit;
    I := 0;
    while I < Count-1 do
    begin
      if PMapRecArray(MapPtr)^[I].Key > PMapRecArray(MapPtr)^[I+1].Key then
      begin
        Temp := PMapRecArray(MapPtr)^[I];
        PMapRecArray(MapPtr)^[I] := PMapRecArray(MapPtr)^[I+1];
        PMapRecArray(MapPtr)^[I+1] := Temp;
        if I <> 0 then
          Dec (I)
        else
          Inc (I);
      end
      else
        Inc (I);
    end;
  end;




  function FindInMap64 ( MapPtr: Pointer;  Count: Integer;  const Key;  out Value ): {Found}Boolean;

  var
    Top, Bottom: Integer;
    Cur: Integer;

  begin
    Result := False;
    if Count = 0 then Exit;

    if Count = 1 then
      if PMapRecArray(MapPtr)^[0].Key = Longword(Key) then
      begin
        Longword(Value) := PMapRecArray(MapPtr)^[0].Value;
        Result := True;
        Exit;
      end;

    Bottom := 0;
    Top := Count;
    repeat

      Cur := Bottom + (Top - Bottom) div 2;
      if Longword(Key) = PMapRecArray(MapPtr)^[Cur].Key then
      begin
        Longword(Value) := PMapRecArray(MapPtr)^[Cur].Value;
        Result := True;
        Exit;
      end;

      if Longword(Key) < PMapRecArray(MapPtr)^[Cur].Key then
        Top := Cur - 1
      else
        Bottom := Cur + 1;

    until Top < Bottom;
  end;




end.

