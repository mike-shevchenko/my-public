unit SubStreams;

interface

uses
  Classes;

//======================================================================================================================
type
//----------------------------------------------------------------------------------------------------------------------

  TSubStream = class(TStream)
  {
    This stream represents a contiguous portion of some source stream specified in constructor.
    Each TSubStream method restores source stream position after the method call completes.
  }

  private
    FStreamPosition: Int64;
    FStream: TStream;
    FStart: Int64;
    FSize: Int64;

  public
    constructor Create(Stream: TStream; Start, Size: Int64);

    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

//======================================================================================================================
implementation /////////////////////////////////////////////////////////////////////////////////////////////////////////
//----------------------------------------------------------------------------------------------------------------------

//======================================================================================================================
// TSubStream
//----------------------------------------------------------------------------------------------------------------------

constructor TSubStream.Create(Stream: TStream; Start, Size: Int64);

begin
  FStream := Stream;
  FStart := Start;
  FSize := Size;

  Assert(FStart >= 0, 'TSubStream.Create: Start should be >= 0.');
  Assert(FStart + FSize <= FStream.Size, 'TSubStream.Create: Start + Size should be <= Stream.Size.');

  FStreamPosition := FStart;
end;

//----------------------------------------------------------------------------------------------------------------------

function TSubStream.Read(var Buffer; Count: Integer): Longint;

var
  OriginalPosition: Int64;

begin
  OriginalPosition := FStream.Position;
  FStream.Seek(FStreamPosition, soBeginning);
  try
    Result := FStream.Read(Buffer, Count);
    FStreamPosition := FStream.Position;
  finally
    FStream.Seek(OriginalPosition, soBeginning);
  end;
end;

//----------------------------------------------------------------------------------------------------------------------

function TSubStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;

begin
  case Origin of

    soBeginning:
      FStreamPosition := FStart + Offset;

    soCurrent:
      FStreamPosition := FStreamPosition + Offset;

    soEnd:
      FStreamPosition := FStart + FSize + Offset;

  else
    Assert(False);
  end;

  Assert(FStreamPosition >= FStart, 'TSubStream.Seek: New position should be >= Start.');
  Assert(FStreamPosition <= FStart + FSize, 'TSubStream.Seek: New position should be <= Start + Size.');

  Result := FStreamPosition - FStart;
end;

//----------------------------------------------------------------------------------------------------------------------

function TSubStream.Write(const Buffer; Count: Integer): Longint;

begin
  Result := 0; // Warning suppress.
  Assert(False, 'TSubStream.Write: TSubStream is a read-only stream.');
end;

//======================================================================================================================
end.


