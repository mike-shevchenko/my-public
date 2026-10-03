
{*****************************************************************************}
{                                                                             }
{    Tnt Delphi Unicode Controls                                              }
{      http://home.ccci.org/wolbrink/tnt/delphi_unicode_controls.htm          }
{        Version: 2.0.23                                                      }
{                                                                             }
{    Copyright (c) 2002, 2003 Troy Wolbrink (troy.wolbrink@ccci.org)          }
{                                                                             }
{*****************************************************************************}

unit TntDesignEditors_Design;

{$INCLUDE ..\TntCompilers.inc}

interface

uses
  Classes, Messages, Windows, Graphics, Controls, Forms, TypInfo,
  {$IFDEF COMPILER_6_UP} DesignIntf, DesignEditors, VCLEditors; {$ELSE} DsgnIntf; {$ENDIF}

type
  {$IFDEF COMPILER_6_UP}
  ICreateDesigner = IDesigner;
  {$ELSE}
  ICreateDesigner = IFormDesigner;
  {$ENDIF}

  {$IFDEF COMPILER_6_UP}
  TWideStringProperty = class(TPropertyEditor, ICustomPropertyDrawing)
  {$ELSE}
  TWideStringProperty = class(TPropertyEditor)
  {$ENDIF}
  private
    FActivateWithoutGetValue: Boolean;
    FPropList: PInstPropList;
  protected
    {$IFDEF COMPILER_6_UP}
    procedure SetPropEntry(Index: Integer; AInstance: TPersistent; APropInfo: PPropInfo); override;
    {$ELSE}
    procedure SetPropEntry(Index: Integer; AInstance: TPersistent; APropInfo: PPropInfo);
    {$ENDIF}
    function GetWideStrValueAt(Index: Integer): WideString;
    function GetWideStrValue: WideString;
    procedure SetWideStrValue(const Value: WideString);
    function GetWideVisualValue: WideString;
  public
    constructor Create(const ADesigner: ICreateDesigner; APropCount: Integer); override;
    destructor Destroy; override;
    {$IFNDEF COMPILER_6_UP}
    procedure Initialize; override;
    {$ENDIF}
    procedure Activate; override;
    procedure PropDrawName(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean); {$IFNDEF COMPILER_6_UP} override; {$ENDIF}
    procedure PropDrawValue(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean); {$IFNDEF COMPILER_6_UP} override; {$ENDIF}
    function AllEqual: Boolean; override;
    function GetEditLimit: Integer; override;
    function GetValue: AnsiString; override;
    procedure SetValue(const Value: AnsiString); override;
    {$IFDEF MULTI_LINE_STRING_EDITOR}
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
    {$ENDIF}
  end;

  TWideCaptionProperty = class(TWideStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
  end;

function GetObjectInspectorForm: TCustomForm;
procedure EditPropertyWithDialog(Component: TPersistent; const PropName: AnsiString; const Designer: ICreateDesigner);

procedure Register;

implementation

uses
  SysUtils, StdCtrls, TntClasses, TntGraphics, TntControls, TntTypInfo,
  TntSysUtils, TntStrEdit_Design;

procedure Register;
begin
  RegisterPropertyEditor(TypeInfo(WideString), nil, '', TWideStringProperty);
  RegisterPropertyEditor(TypeInfo(TWideCaption), nil, '', TWideCaptionProperty);
end;

{//------------------------------
//  Helpful discovery routines to explore the components and classes inside the IDE...
//
procedure EnumerateComponents(Comp: TComponent);
var
  i: integer;
begin
  for i := Comp.ComponentCount - 1 downto 0 do
    MessageBoxW(0, PWideChar(WideString(Comp.Components[i].Name + ': ' + Comp.Components[i].ClassName)),
      PWideChar(WideString(Comp.Name)), 0);
end;

procedure EnumerateClasses(Comp: TComponent);
var
  AClass: TClass;
begin
  AClass := Comp.ClassType;
  repeat
    MessageBoxW(0, PWideChar(WideString(AClass.ClassName)),
      PWideChar(WideString(Comp.Name)), 0);
    AClass := Aclass.ClassParent;
  until AClass = nil;
end;
//------------------------------}

//------------------------------
function GetIdeMainForm: TCustomForm;
var
  Comp: TComponent;
begin
  Result := nil;
  if Application <> nil then begin
    Comp := Application.FindComponent('AppBuilder');
    if Comp is TCustomForm then
      Result := TCustomForm(Comp);
  end;
end;

function GetObjectInspectorForm: TCustomForm;
var
  Comp: TComponent;
  IdeMainForm: TCustomForm;
begin
  Result := nil;
  IdeMainForm := GetIdeMainForm;
  if IdeMainForm <> nil then begin
    Comp := IdeMainForm.FindComponent('PropertyInspector');
    if Comp is TCustomForm then
      Result := TCustomForm(Comp);
  end;
end;

function GetOIInspListBox: TWinControl;
var
  ObjectInspectorForm: TCustomForm;
  Comp: TComponent;
begin
  Result := nil;
  ObjectInspectorForm := GetObjectInspectorForm;
  if ObjectInspectorForm <> nil then begin
    Comp := ObjectInspectorForm.FindComponent('PropList');
    if Comp is TWinControl then
      Result := TWinControl(Comp);
  end;
end;

function GetOIPropInspEdit: TCustomEdit{TNT-ALLOW TCustomEdit};
var
  OIInspListBox: TWinControl;
  Comp: TComponent;
begin
  Result := nil;
  OIInspListBox := GetOIInspListBox;
  if OIInspListBox <> nil then begin
    Comp := OIInspListBox.FindComponent('EditControl');
    if Comp is TCustomEdit{TNT-ALLOW TCustomEdit} then
      Result := TCustomEdit{TNT-ALLOW TCustomEdit}(Comp);
  end;
end;
//------------------------------

type TAccessWinControl = class(TWinControl);

{ TWideStringProperty }

var
  WideStringPropertyCount: Integer = 0;

constructor TWideStringProperty.Create(const ADesigner: ICreateDesigner; APropCount: Integer);
begin
  inherited;
  Inc(WideStringPropertyCount);
  GetMem(FPropList, APropCount * SizeOf(TInstProp));
end;

procedure ConvertObjectInspectorBackToANSI;
var
  Edit: TCustomEdit{TNT-ALLOW TCustomEdit};
begin
  if (Win32PlatformIsUnicode) then begin
    Edit := GetOIPropInspEdit;
    if Assigned(Edit)
    and IsWindowUnicode(Edit.Handle) then
      TAccessWinControl(Edit).RecreateWnd;
  end;
end;

destructor TWideStringProperty.Destroy;
begin
  Dec(WideStringPropertyCount);
  if (WideStringPropertyCount = 0) then
    ConvertObjectInspectorBackToANSI;
  if FPropList <> nil then
    FreeMem(FPropList, PropCount * SizeOf(TInstProp));
  inherited;
end;

{$IFDEF COMPILER_5} // verified against VCL source in Delphi 5 and BCB 5
type
  THackPropertyEditor = class
    FDesigner: IFormDesigner;
    FPropList: PInstPropList;
  end;
{$ENDIF}

{$IFNDEF COMPILER_6_UP}
procedure TWideStringProperty.Initialize;
var
  I: Integer;
begin
  for I := 0 to PropCount - 1 do
    with THackPropertyEditor(Self).FPropList[I] do
      SetPropEntry(I, Instance, PropInfo);
end;
{$ENDIF}

procedure TWideStringProperty.Activate;
var
  Edit: TCustomEdit{TNT-ALLOW TCustomEdit};
begin
  FActivateWithoutGetValue := True;
  if (Win32PlatformIsUnicode) then begin
    Edit := GetOIPropInspEdit;
    if Assigned(Edit)
    and (not IsWindowUnicode(Edit.Handle)) then
      ReCreateUnicodeWnd(Edit, 'EDIT', True);
  end;
end;

procedure TWideStringProperty.SetPropEntry(Index: Integer;
  AInstance: TPersistent; APropInfo: PPropInfo);
begin
  inherited;
  with FPropList^[Index] do
  begin
    Instance := AInstance;
    PropInfo := APropInfo;
  end;
end;

function TWideStringProperty.GetWideStrValueAt(Index: Integer): WideString;
begin
  with FPropList^[Index] do Result := GetWideStrProp(Instance, PropInfo);
end;

function TWideStringProperty.GetWideStrValue: WideString;
begin
  Result := GetWideStrValueAt(0);
end;

procedure TWideStringProperty.SetWideStrValue(const Value: WideString);
var
  I: Integer;
begin
  for I := 0 to PropCount - 1 do
    with FPropList^[I] do SetWideStrProp(Instance, PropInfo, Value);
  Modified;
end;

function TWideStringProperty.GetWideVisualValue: WideString;
begin
  if AllEqual then
    Result := GetWideStrValue
  else
    Result := '';
end;

procedure TWideStringProperty.PropDrawName(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
begin
  {$IFDEF COMPILER_6_UP}
  DefaultPropertyDrawName(Self, ACanvas, ARect);
  {$ELSE}
  inherited;
  {$ENDIF}
end;

procedure TWideStringProperty.PropDrawValue(ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
begin
  WideCanvasTextRect(ACanvas, ARect, ARect.Left + 1, ARect.Top + 1, GetWideVisualValue);
end;

function TWideStringProperty.AllEqual: Boolean;
var
  I: Integer;
  V: WideString;
begin
  Result := False;
  if PropCount > 1 then
  begin
    V := GetWideStrValue;
    for I := 1 to PropCount - 1 do
      if GetWideStrValueAt(I) <> V then Exit;
  end;
  Result := True;
end;

function TWideStringProperty.GetEditLimit: Integer;
var
  Edit: TCustomEdit{TNT-ALLOW TCustomEdit};
begin
  Result := MaxInt;
  // GetEditLimit is called right after the inplace editor text has been set
  if Win32PlatformIsUnicode then begin
    Edit := GetOIPropInspEdit;
    if Assigned(Edit) then begin
      TntControl_SetText(Edit, GetWideStrValue);
      TntControl_SetHint(Edit, GetWideStrValue);
    end;
  end;
end;

function TWideStringProperty.GetValue: AnsiString;
begin
  FActivateWithoutGetValue := False;
  Result := GetWideStrValue;
end;

procedure TWideStringProperty.SetValue(const Value: AnsiString);
var
  Edit: TCustomEdit{TNT-ALLOW TCustomEdit};
begin
  if (not FActivateWithoutGetValue) then begin
    Edit := GetOIPropInspEdit;
    if Assigned(Edit) and Win32PlatformIsUnicode then
      SetWideStrValue(TntControl_GetText(Edit))
    else
      SetWideStrValue(Value);
  end;
end;

{$IFDEF MULTI_LINE_STRING_EDITOR}
function TWideStringProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

procedure TWideStringProperty.Edit;
var
  Temp: WideString;
begin
  with TTntStrEditDlg.Create(Application) do
  try
    PrepareForWideStringEdit;
    Memo.Text := GetWideStrValue;
    UpdateStatus(nil);
    if ShowModal = mrOk then begin
      Temp := Memo.Text;
      while (Length(Temp) > 0) and (Temp[Length(Temp)] < ' ') do
        System.Delete(Temp, Length(Temp), 1); { trim control characters from end }
      SetWideStrValue(Temp);
    end;
  finally
    Free;
  end;
end;
{$ENDIF}

{ TWideCaptionProperty }

function TWideCaptionProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paAutoUpdate];
end;

{ TPropertyEditorWithDialog }
type
  TPropertyEditorWithDialog = class
  private
    FPropName: AnsiString;
    {$IFDEF COMPILER_6_UP}
    procedure CheckEditProperty(const Prop: IProperty);
    {$ELSE}
    procedure CheckEditProperty(Prop: TPropertyEditor);
    {$ENDIF}
    procedure EditProperty(Component: TPersistent; const PropName: AnsiString; const Designer: ICreateDesigner);
  end;

{$IFDEF COMPILER_6_UP}
procedure TPropertyEditorWithDialog.CheckEditProperty(const Prop: IProperty);
begin
  if Prop.GetName = FPropName then
    Prop.Edit;
end;

procedure TPropertyEditorWithDialog.EditProperty(Component: TPersistent; const PropName: AnsiString; const Designer: ICreateDesigner);
var
  Components: IDesignerSelections;
begin
  FPropName := PropName;
  Components := TDesignerSelections.Create;
  Components.Add(Component);
  GetComponentProperties(Components, [tkClass], Designer, CheckEditProperty);
end;
{$ELSE}
procedure TPropertyEditorWithDialog.CheckEditProperty(Prop: TPropertyEditor);
begin
  if Prop.GetName = FPropName then
    Prop.Edit;
end;

procedure TPropertyEditorWithDialog.EditProperty(Component: TPersistent; const PropName: AnsiString; const Designer: ICreateDesigner);
var
  Components: TDesignerSelectionList;
begin
  FPropName := PropName;
  Components := TDesignerSelectionList.Create;
  try
    Components.Add(Component);
    GetComponentProperties(Components, [tkClass], Designer, CheckEditProperty);
  finally
    Components.Free;
  end;
end;
{$ENDIF}

procedure EditPropertyWithDialog(Component: TPersistent; const PropName: AnsiString; const Designer: ICreateDesigner);
begin
  with TPropertyEditorWithDialog.Create do
  try
    EditProperty(Component, PropName, Designer);
  finally
    Free;
  end;
end;

initialization

finalization
  ConvertObjectInspectorBackToANSI;

end.
