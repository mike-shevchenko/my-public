unit RasterChars;

interface

//======================================================================================================================
type
//----------------------------------------------------------------------------------------------------------------------

  TRasterChar = class

  private
    FData: array of array of Boolean; // Array of pixel rows.

    function GetWidth: Integer;
    procedure SetWidth(Value: Integer);
    function GetHeight: Integer;
    procedure SetHeight(Value: Integer);
    function GetPixels(X, Y: Integer): Boolean;
    procedure SetPixels(X, Y: Integer; Value: Boolean);

  public
    constructor Create(Width, Height: Integer);
    property Width: Integer read GetWidth write SetWidth;
    property Height: Integer read GetHeight write SetHeight;
    property Pixels[X, Y: Integer]: Boolean read GetPixels write SetPixels;
  end;

//======================================================================================================================
implementation /////////////////////////////////////////////////////////////////////////////////////////////////////////
//----------------------------------------------------------------------------------------------------------------------

//======================================================================================================================
// TRasterChar
//----------------------------------------------------------------------------------------------------------------------

constructor TRasterChar.Create(Width, Height: Integer);

begin
  Assert(Width >= 0);
  Assert(Height > 0);

  SetLength(FData, Height, Width);
end;

//----------------------------------------------------------------------------------------------------------------------

function TRasterChar.GetWidth: Integer;

begin
  Result := Length(FData[0]);
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TRasterChar.SetWidth(Value: Integer);

begin
  Assert(Value >= 0);

  SetLength(FData, Length(FData), Value);
end;

//----------------------------------------------------------------------------------------------------------------------

function TRasterChar.GetHeight: Integer;

begin
  Result := Length(FData);
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TRasterChar.SetHeight(Value: Integer);

begin
  Assert(Value > 0);

  SetLength(FData, Value);
end;

//----------------------------------------------------------------------------------------------------------------------

function TRasterChar.GetPixels(X, Y: Integer): Boolean;

begin
  Assert(X >= 0);
  Assert(X < Width);
  Assert(Y >= 0);
  Assert(Y < Height);

  Result := FData[Y, X];
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TRasterChar.SetPixels(X, Y: Integer; Value: Boolean);

begin
  Assert(X >= 0);
  Assert(X < Width);
  Assert(Y >= 0);
  Assert(Y < Height);

  FData[Y, X] := Value;
end;

//======================================================================================================================
end.


