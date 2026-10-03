
{*****************************************************************************}
{                                                                             }
{    Tnt Delphi Unicode Controls                                              }
{      http://home.ccci.org/wolbrink/tnt/delphi_unicode_controls.htm          }
{        Version: 2.0.23                                                      }
{                                                                             }
{    Copyright (c) 2002, 2003 Troy Wolbrink (troy.wolbrink@ccci.org)          }
{                                                                             }
{*****************************************************************************}

unit TntActions_Design;

{$INCLUDE ..\TntCompilers.inc}

interface

uses
  Classes, {$IFDEF COMPILER_6_UP} DesignIntf; {$ELSE} DsgnIntf; {$ENDIF}

{ TTntDesignerSelections }
type
  TTntDesignerSelections = class(TInterfacedObject, IDesignerSelections)
  private
    FList: TList;
    {$IFNDEF COMPILER_6_UP}
    function IDesignerSelections.Add = Intf_Add;
    function Intf_Add(const Item: IPersistent): Integer;
    function IDesignerSelections.Get = Intf_Get;
    function Intf_Get(Index: Integer): IPersistent;
    {$ENDIF}
  protected
    function Add(const Item: TPersistent): Integer;
    function Equals(const List: IDesignerSelections): Boolean;
    {$IFDEF COMPILER_6_UP}
    function Get(Index: Integer): TPersistent;
    {$ENDIF}
    function GetCount: Integer;
    property Count: Integer read GetCount;
    {$IFDEF COMPILER_6_UP}
    property Items[Index: Integer]: TPersistent read Get; default;
    {$ENDIF}
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure ReplaceSelection(const OldInst, NewInst: TPersistent);
  end;

procedure Register;

implementation

uses
  ActnList, TntActnList, StdActns, TntStdActns,
  {$IFDEF COMPILER_6_UP}
     ExtActns, TntExtActns, ListActns, TntListActns,
     {$IFDEF DATASNAP} DBClientActns, TntDBClientActns, {$ENDIF}
     BandActn, TntBandActn,
  {$ENDIF}
  DBActns, TntDBActns;

procedure Register;
begin
  RegisterClass(TTntAction);
  // StdActns
  RegisterClass(TTntEditAction);
  RegisterClass(TTntEditCut);
  RegisterClass(TTntEditCopy);
  RegisterClass(TTntEditPaste);
  RegisterClass(TTntEditSelectAll);
  RegisterClass(TTntEditUndo);
  RegisterClass(TTntEditDelete);
  RegisterClass(TTntWindowAction);
  RegisterClass(TTntWindowClose);
  RegisterClass(TTntWindowCascade);
  RegisterClass(TTntWindowTileHorizontal);
  RegisterClass(TTntWindowTileVertical);
  RegisterClass(TTntWindowMinimizeAll);
  RegisterClass(TTntWindowArrange);
  RegisterClass(TTntHelpAction);
  RegisterClass(TTntHelpContents);
  RegisterClass(TTntHelpTopicSearch);
  RegisterClass(TTntHelpOnHelp);
{$IFDEF COMPILER_6_UP}
  RegisterClass(TTntHelpContextAction);
  RegisterClass(TTntFileOpen);
  RegisterClass(TTntFileOpenWith);
  RegisterClass(TTntFileSaveAs);
  RegisterClass(TTntFilePrintSetup);
  {$IFDEF COMPILER_7_UP}
  RegisterClass(TTntFilePageSetup);
  {$ENDIF}
  RegisterClass(TTntFileExit);
  RegisterClass(TTntSearchFind);
  RegisterClass(TTntSearchReplace);
  RegisterClass(TTntSearchFindFirst);
  RegisterClass(TTntSearchFindNext);
  RegisterClass(TTntFontEdit);
  RegisterClass(TTntColorSelect);
  RegisterClass(TTntPrintDlg);
  // ExtActns
  RegisterClass(TTntFileRun);
  RegisterClass(TTntRichEditAction);
  RegisterClass(TTntRichEditBold);
  RegisterClass(TTntRichEditItalic);
  RegisterClass(TTntRichEditUnderline);
  RegisterClass(TTntRichEditStrikeOut);
  RegisterClass(TTntRichEditBullets);
  RegisterClass(TTntRichEditAlignLeft);
  RegisterClass(TTntRichEditAlignRight);
  RegisterClass(TTntRichEditAlignCenter);
  RegisterClass(TTntPreviousTab);
  RegisterClass(TTntNextTab);
  RegisterClass(TTntOpenPicture);
  RegisterClass(TTntSavePicture);
  RegisterClass(TTntURLAction);
  RegisterClass(TTntBrowseURL);
  RegisterClass(TTntDownLoadURL);
  RegisterClass(TTntSendMail);
  RegisterClass(TTntListControlCopySelection);
  RegisterClass(TTntListControlDeleteSelection);
  RegisterClass(TTntListControlSelectAll);
  RegisterClass(TTntListControlClearSelection);
  RegisterClass(TTntListControlMoveSelection);
  // ListActns
  RegisterClass(TTntStaticListAction);
  RegisterClass(TTntVirtualListAction);
{$ENDIF}
  // DBActns
  RegisterClass(TTntDataSetAction);
  RegisterClass(TTntDataSetFirst);
  RegisterClass(TTntDataSetPrior);
  RegisterClass(TTntDataSetNext);
  RegisterClass(TTntDataSetLast);
  RegisterClass(TTntDataSetInsert);
  RegisterClass(TTntDataSetDelete);
  RegisterClass(TTntDataSetEdit);
  RegisterClass(TTntDataSetPost);
  RegisterClass(TTntDataSetCancel);
  RegisterClass(TTntDataSetRefresh);
{$IFDEF COMPILER_6_UP}
  {$IFDEF DATASNAP}
  // DBClientActns
  RegisterClass(TTntClientDataSetApply);
  RegisterClass(TTntClientDataSetRevert);
  RegisterClass(TTntClientDataSetUndo);
  {$ENDIF}
  // BandActn
  RegisterClass(TTntCustomizeActionBars);
{$ENDIF}
end;

{ TTntDesignerSelections }

function TTntDesignerSelections.Add(const Item: TPersistent): Integer;
begin
  Result := FList.Add(Item);
end;

constructor TTntDesignerSelections.Create;
begin
  inherited;
  FList := TList.Create;
end;

destructor TTntDesignerSelections.Destroy;
begin
  FList.Free;
  inherited;
end;

function TTntDesignerSelections.Equals(const List: IDesignerSelections): Boolean;
var
  I: Integer;
  {$IFNDEF COMPILER_6_UP}
  P1, P2: IPersistent;
  {$ENDIF}
begin
  Result := False;
  if List.Count <> Count then Exit;
  for I := 0 to Count - 1 do
  begin
    {$IFDEF COMPILER_6_UP}
    if Items[I] <> List[I] then Exit;
    {$ELSE}
    P1 := Intf_Get(I);
    P2 := List[I];
    if ((P1 = nil) and (P2 <> nil)) or
      (P2 = nil) or not P1.Equals(P2) then Exit;
    {$ENDIF}
  end;
  Result := True;
end;

{$IFDEF COMPILER_6_UP}
function TTntDesignerSelections.Get(Index: Integer): TPersistent;
begin
  Result := TPersistent(FList[Index]);
end;
{$ENDIF}

function TTntDesignerSelections.GetCount: Integer;
begin
  Result := FList.Count;
end;

{$IFNDEF COMPILER_6_UP}
function TTntDesignerSelections.Intf_Add(const Item: IPersistent): Integer;
begin
  Result := Add(ExtractPersistent(Item));
end;

function TTntDesignerSelections.Intf_Get(Index: Integer): IPersistent;
begin
  Result := MakeIPersistent(TPersistent(FList[Index]));
end;
{$ENDIF}

procedure TTntDesignerSelections.ReplaceSelection(const OldInst, NewInst: TPersistent);
var
  Idx: Integer;
begin
  Idx := FList.IndexOf(OldInst);
  if Idx <> -1 then
    FList[Idx] := NewInst;
end;

//------------------------

function GetTntActionClass(OldActionClass: TContainedActionClass): TContainedActionClass;
begin
  Result := TContainedActionClass(GetClass('TTnt' + Copy(OldActionClass.ClassName, 2, Length(OldActionClass.ClassName))));
end;

type
  TAccessContainedAction = class(TContainedAction);

function UpgradeAction(ActionList: TTntActionList; OldAction: TContainedAction): TContainedAction;
var
  Name: TComponentName;
  i: integer;
  NewActionClass: TContainedActionClass;
begin
  Result := nil;
  if (OldAction = nil) or (OldAction.Owner = nil) or (OldAction.Name = '') then
    Exit;

  NewActionClass := GetTntActionClass(TContainedActionClass(OldAction.ClassType));
  if NewActionClass <> nil then begin
    // create new action
    Result := NewActionClass.Create(OldAction.Owner) as TContainedAction;
    {$IFDEF COMPILER_6_UP}
    Include(TAccessContainedAction(Result).FComponentStyle, csTransient);
    {$ENDIF}
    // copy base class info
    {$IFDEF COMPILER_6_UP}
    Result.ActionComponent := OldAction.ActionComponent;
    {$ENDIF}
    Result.Category := OldAction.Category; { Assign Category before ActionList/Index to avoid flicker. }
    Result.ActionList := ActionList;
    Result.Index := OldAction.Index;
    // assign props
    Result.Assign(OldAction);
    // point all links to this new action
    for i := TAccessContainedAction(OldAction).FClients.Count - 1 downto 0 do
      TBasicActionLink(TAccessContainedAction(OldAction).FClients[i]).Action := Result;
    // free old object, preserve name...
    Name := OldAction.Name;
    OldAction.Free;
    Result.Name := Name; { link up to old name }
    {$IFDEF COMPILER_6_UP}
    Exclude(TAccessContainedAction(Result).FComponentStyle, csTransient);
    {$ENDIF}
  end;
end;

procedure TntActionList_UpgradeActionListItems(ActionList: TTntActionList);
{$IFDEF COMPILER_6_UP}
type ITntDesigner = IDesigner;
{$ELSE}
type ITntDesigner = IFormDesigner;
{$ENDIF}
var
  DesignerNotify: IDesignerNotify;
  Designer: ITntDesigner;
  TntSelections: TTntDesignerSelections;
  i: integer;
  OldAction, NewAction: TContainedAction;
begin
  DesignerNotify := FindRootDesigner(ActionList);
  if (DesignerNotify <> nil) then begin
    DesignerNotify.QueryInterface(ITntDesigner, Designer);
    if (Designer <> nil) then begin
      TntSelections := TTntDesignerSelections.Create;
      try
        Designer.GetSelections(TntSelections);
        for i := ActionList.ActionCount - 1 downto 0 do begin
          OldAction := ActionList.Actions[i];
          NewAction := UpgradeAction(ActionList, OldAction);
          if (NewAction <> nil) then
            TntSelections.ReplaceSelection(OldAction, NewAction);
        end;
        Designer.SetSelections(TntSelections);
      finally
        TntSelections.Free;
      end;
    end;
  end;
end;

initialization
  UpgradeActionListItemsProc := TUpgradeActionListItemsProc(@TntActionList_UpgradeActionListItems);

end.
