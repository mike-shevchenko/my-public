object DebugForm: TDebugForm
  Left = 314
  Top = 227
  Width = 408
  Height = 301
  Caption = 'DebugForm'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object MainPageControl: TPageControl
    Left = 0
    Top = 0
    Width = 400
    Height = 274
    ActivePage = FonFileTabSheet
    Align = alClient
    TabOrder = 0
    object FonFileTabSheet: TTabSheet
      Caption = 'FonFile'
      object FonFileMemo: TMemo
        Left = 0
        Top = 0
        Width = 392
        Height = 212
        Align = alClient
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
      end
      object FonFilePanel: TPanel
        Left = 0
        Top = 212
        Width = 392
        Height = 34
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 1
        object FonSaveToFileButton: TButton
          Left = 4
          Top = 8
          Width = 57
          Height = 21
          Caption = 'Save'
          TabOrder = 0
          OnClick = FonSaveToFileButtonClick
        end
      end
    end
  end
  object FonSaveDialog: TSaveDialog
    DefaultExt = 'fon'
    Filter = 'All files(*.*)|*.*|Font directories (*.fon)|*.fon'
    Options = [ofPathMustExist, ofNoReadOnlyReturn, ofEnableIncludeNotify, ofEnableSizing, ofForceShowHidden]
    Title = 'FonEd - DebugForm - Save FonFile'
    Left = 48
    Top = 76
  end
end
