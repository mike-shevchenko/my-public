
{*****************************************************************************}
{                                                                             }
{    Tnt Delphi Unicode Controls                                              }
{      http://home.ccci.org/wolbrink/tnt/delphi_unicode_controls.htm          }
{        Version: 2.0.23                                                      }
{                                                                             }
{    Copyright (c) 2002, 2003 Troy Wolbrink (troy.wolbrink@ccci.org)          }
{                                                                             }
{*****************************************************************************}

unit TntDBGrids_Design;

{$INCLUDE ..\TntCompilers.inc}

interface

uses
  {$IFDEF COMPILER_6_UP} DesignEditors, DesignIntf; {$ELSE} DsgnIntf; {$ENDIF}

type
  TTntDBGridEditor = class(TComponentEditor)
  public
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string{TNT-ALLOW string}; override;
    function GetVerbCount: Integer; override;
  end;

procedure Register;

implementation

uses
  TntDBGrids, DsnDBCst, TntDesignEditors_Design;

procedure Register;
begin
  RegisterComponentEditor(TTntDBGrid, TTntDBGridEditor);
end;

{ TTntDBGridEditor }

function TTntDBGridEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TTntDBGridEditor.GetVerb(Index: Integer): string{TNT-ALLOW string};
begin
  Result := DsnDBCst.SDBGridColEditor;
end;

procedure TTntDBGridEditor.ExecuteVerb(Index: Integer);
begin
  EditPropertyWithDialog(Component, 'Columns', Designer);
end;

end.
