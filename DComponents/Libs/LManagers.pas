unit LManagers;

{
  This unit represents a concept of bi-directional linked list with effective memory management.
}

interface

//======================================================================================================================
type
//----------------------------------------------------------------------------------------------------------------------

  PLNode = ^TLNode;

  TLNode = object

    Data: Pointer;
    Next: PLNode;
    Prev: PLNode;

    function Init(AData: Pointer; ANext, APrev: PLNode): PLNode; // Returns @Self.
  end;

//----------------------------------------------------------------------------------------------------------------------

  TLManager = class; {forward;}

//----------------------------------------------------------------------------------------------------------------------

  PLList = ^TLList;

  TLList = object

    LManager: TLManager;

    Head: TLNode; // Non-valuable before-first node; use Head.Next as first node reference.
    Tail: PLNode; // Points to the last node.

    procedure Init(ALManager: TLManager); // Should be called on an uninitialized object. Makes an empty list.
    procedure Clear; // Makes the list empty. Should be called to free memory.

    function  IsEmpty: Boolean;
    function  Append(LNode: PLNode): {LNode}PLNode;
    function  AppendNewLNode(Data: Pointer): {NewLNode}PLNode;
    procedure DeleteLNode(LNode: PLNode);
    function  Find(Data: Pointer): PLNode; // nil if not found.
    function  CalcCount: Integer;
    procedure Assign(const LList: TLList);
  end;

//----------------------------------------------------------------------------------------------------------------------

  TLManager = class

  private
    FLPoolSize: Integer;
    FLPools: Pointer{as PLPool};
    FFreeLNodes: PLNode;

  public
    constructor Create(PoolSize: Integer);
    destructor Destroy; override;

    function NewLNode: PLNode; // New node fields are not initialized.
    procedure FreeLNode(LNode: PLNode);
    procedure FreeLList(LList: PLList);
  end;

//======================================================================================================================
implementation /////////////////////////////////////////////////////////////////////////////////////////////////////////
//----------------------------------------------------------------------------------------------------------------------

//======================================================================================================================
// TLNode
//----------------------------------------------------------------------------------------------------------------------

function TLNode.Init(AData: Pointer; ANext, APrev: PLNode): PLNode;

begin
  Data := AData;
  Next := ANext;
  Prev := APrev;
  Result := @Self;
end;

//======================================================================================================================
// TLList
//----------------------------------------------------------------------------------------------------------------------

procedure TLList.Init(ALManager: TLManager);

begin
  LManager := ALManager;
  Head.Next := nil;
  Head.Prev := nil;
  Head.Data := nil;
  Tail := @Head;
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TLList.Clear;

begin
  LManager.FreeLList(@Self);
end;

//----------------------------------------------------------------------------------------------------------------------

function TLList.IsEmpty: Boolean;

begin
  Result := (not Assigned(Head.Next));
end;

//----------------------------------------------------------------------------------------------------------------------

function TLList.Append(LNode: PLNode): {LNode}PLNode;

begin
  Tail.Next := LNode;
  LNode.Next := nil;
  LNode.Prev := Tail;
  Tail := LNode;
  Result := LNode;
end;

//----------------------------------------------------------------------------------------------------------------------

function TLList.AppendNewLNode(Data: Pointer): {NewLNode}PLNode;

begin
  Result := Append(LManager.NewLNode);
  Result.Data := Data;
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TLList.DeleteLNode(LNode: PLNode);

begin
  LNode.Prev.Next := LNode.Next;
  if Assigned(LNode.Next) then
    LNode.Next.Prev := LNode.Prev
  else
    Tail := LNode.Prev;

  LManager.FreeLNode(LNode);
end;

//----------------------------------------------------------------------------------------------------------------------

function TLList.Find(Data: Pointer): PLNode;

begin
  Result := Head.Next;
  while Assigned(Result) do
  begin
    if Result.Data = Data then Exit;
    Result := Result.Next;
  end;
end;

//----------------------------------------------------------------------------------------------------------------------

function TLList.CalcCount: Integer;

var
  L: PLNode;

begin
  L := Head.Next;
  Result := 0;
  while Assigned(L) do
  begin
    Inc(Result);
    L := L.Next;
  end;
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TLList.Assign(const LList: TLList);

var
  Run: PLNode;

begin
  Clear;

  Run := LList.Head.Next;
  while Assigned(Run) do
  begin
    Tail.Next := LManager.NewLNode.Init(Run.Data, {Next}nil, {Prev}Tail);
    Tail := Tail.Next;
    Run := Run.Next;
  end;
end;

//======================================================================================================================
// TLManager
//----------------------------------------------------------------------------------------------------------------------

type

  PLNodeArray = ^TLNodeArray;

  TLNodeArray = array [0..16383] of TLNode;

  //....................................................................................................................

  PLPool = ^TLPool;

  TLPool = record

    LNodes: PLNodeArray; // Nodes are linked using Next field only.
    Next: PLPool;
  end;

//----------------------------------------------------------------------------------------------------------------------

constructor TLManager.Create(PoolSize: Integer);

begin
  Assert(PoolSize > 0);
  FLPoolSize := PoolSize;
end;

//----------------------------------------------------------------------------------------------------------------------

destructor TLManager.Destroy;

var
  LPoolToFree: PLPool;

begin
  while Assigned(FLPools) do
  begin
    FreeMem(PLPool(FLPools).LNodes);
    LPoolToFree := FLPools;
    FLPools := PLPool(FLPools).Next;
    Dispose(LPoolToFree);
  end;
end;

//----------------------------------------------------------------------------------------------------------------------

function TLManager.NewLNode: PLNode;

var
  NewLPool: PLPool;
  I: Integer;

begin
  if Assigned(FFreeLNodes) then // Give one of free nodes:
  begin
    Result := FFreeLNodes;
    FFreeLNodes := Result.Next;
    Exit;
  end;

  // Allocating a new pool:
  New(NewLPool);
  NewLPool.Next := FLPools;
  FLPools := NewLPool;
  GetMem(NewLPool.LNodes, FLPoolSize * SizeOf(TLNode));
  for I := 0 to FLPoolSize-1 - 1 do // Last LNode should have Next = nil.
    NewLPool.LNodes[I].Next := @NewLPool.LNodes[I+1];
  NewLPool.LNodes[FLPoolSize-1].Next := nil;

  Result := @NewLPool.LNodes[0];
  FFreeLNodes := NewLPool.LNodes[0].Next;
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TLManager.FreeLNode(LNode: PLNode);

begin
  LNode.Next := FFreeLNodes;
  FFreeLNodes := LNode;
end;

//----------------------------------------------------------------------------------------------------------------------

procedure TLManager.FreeLList(LList: PLList);

begin
  LList.Tail.Next := FFreeLNodes;
  FFreeLNodes := LList.Head.Next;

  LList.Head.Next := nil;
  LList.Tail := @LList.Head;
end;

//======================================================================================================================
end.

