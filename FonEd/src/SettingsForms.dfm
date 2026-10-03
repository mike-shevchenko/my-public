object SettingsForm: TSettingsForm
  Left = 253
  Top = 311
  BorderStyle = bsToolWindow
  Caption = 'Settings'
  ClientHeight = 374
  ClientWidth = 179
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  ScreenSnap = True
  SnapBuffer = 8
  Visible = True
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox2: TGroupBox
    Left = 8
    Top = 184
    Width = 160
    Height = 181
    Caption = 'Editor'
    TabOrder = 0
    object Label16: TLabel
      Left = 80
      Top = 15
      Width = 11
      Height = 13
      Caption = 'All'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label4: TLabel
      Left = 107
      Top = 15
      Width = 34
      Height = 13
      Caption = 'Current'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label2: TLabel
      Left = 12
      Top = 35
      Width = 31
      Height = 13
      Caption = 'Paper:'
    end
    object Label3: TLabel
      Left = 12
      Top = 58
      Width = 18
      Height = 13
      Caption = 'Ink:'
    end
    object Label5: TLabel
      Left = 12
      Top = 82
      Width = 45
      Height = 13
      Caption = 'Pixel grid:'
    end
    object Label9: TLabel
      Left = 12
      Top = 105
      Width = 45
      Height = 13
      Caption = 'Char grid:'
    end
    object Memo13: TMemo
      Left = 107
      Top = 32
      Width = 38
      Height = 21
      Cursor = crArrow
      TabStop = False
      Color = 10485760
      Ctl3D = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 0
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentCtl3D = False
      ParentFont = False
      ReadOnly = True
      TabOrder = 0
      WantReturns = False
      OnClick = Memo1Click
    end
    object Memo2: TMemo
      Left = 67
      Top = 32
      Width = 38
      Height = 21
      Cursor = crArrow
      TabStop = False
      Color = clNavy
      Ctl3D = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 0
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentCtl3D = False
      ParentFont = False
      ReadOnly = True
      TabOrder = 1
      WantReturns = False
      OnClick = Memo1Click
    end
    object Memo1: TMemo
      Left = 67
      Top = 55
      Width = 38
      Height = 21
      Cursor = crArrow
      TabStop = False
      Color = clYellow
      Ctl3D = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 0
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentCtl3D = False
      ParentFont = False
      ReadOnly = True
      TabOrder = 2
      WantReturns = False
      OnClick = Memo1Click
    end
    object Memo14: TMemo
      Left = 107
      Top = 55
      Width = 38
      Height = 21
      Cursor = crArrow
      TabStop = False
      Color = clYellow
      Ctl3D = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 0
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentCtl3D = False
      ParentFont = False
      ReadOnly = True
      TabOrder = 3
      WantReturns = False
      OnClick = Memo1Click
    end
    object Memo15: TMemo
      Left = 107
      Top = 79
      Width = 38
      Height = 21
      Cursor = crArrow
      TabStop = False
      Color = clNavy
      Ctl3D = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 0
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentCtl3D = False
      ParentFont = False
      ReadOnly = True
      TabOrder = 4
      WantReturns = False
      OnClick = Memo1Click
    end
    object Memo9: TMemo
      Left = 67
      Top = 79
      Width = 38
      Height = 21
      Cursor = crArrow
      TabStop = False
      Color = clNavy
      Ctl3D = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 0
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentCtl3D = False
      ParentFont = False
      ReadOnly = True
      TabOrder = 5
      WantReturns = False
      OnClick = Memo1Click
    end
    object Memo3: TMemo
      Left = 67
      Top = 102
      Width = 38
      Height = 21
      Cursor = crArrow
      TabStop = False
      Color = clYellow
      Ctl3D = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 0
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentCtl3D = False
      ParentFont = False
      ReadOnly = True
      TabOrder = 6
      WantReturns = False
      OnClick = Memo1Click
    end
    object Memo16: TMemo
      Left = 107
      Top = 102
      Width = 38
      Height = 21
      Cursor = crArrow
      TabStop = False
      Color = clYellow
      Ctl3D = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 0
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentCtl3D = False
      ParentFont = False
      ReadOnly = True
      TabOrder = 7
      WantReturns = False
      OnClick = Memo1Click
    end
    object CheckBox1: TCheckBox
      Left = 12
      Top = 129
      Width = 125
      Height = 17
      Caption = 'Top left char grid'
      TabOrder = 8
    end
    object CheckBox2: TCheckBox
      Left = 12
      Top = 152
      Width = 125
      Height = 17
      Caption = 'Bottom right char grid'
      TabOrder = 9
    end
  end
  object ComboBox1: TComboBox
    Left = 8
    Top = 12
    Width = 160
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    ItemIndex = 0
    TabOrder = 1
    Text = 'Preset1'
    Items.Strings = (
      'Preset1')
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 83
    Width = 160
    Height = 90
    Caption = 'Preview'
    TabOrder = 2
    object Label1: TLabel
      Left = 80
      Top = 15
      Width = 11
      Height = 13
      Caption = 'All'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label6: TLabel
      Left = 107
      Top = 15
      Width = 34
      Height = 13
      Caption = 'Current'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label7: TLabel
      Left = 12
      Top = 35
      Width = 31
      Height = 13
      Caption = 'Paper:'
    end
    object Label8: TLabel
      Left = 12
      Top = 58
      Width = 18
      Height = 13
      Caption = 'Ink:'
    end
    object Memo4: TMemo
      Left = 107
      Top = 32
      Width = 38
      Height = 21
      Cursor = crArrow
      TabStop = False
      Color = 10485760
      Ctl3D = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 0
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentCtl3D = False
      ParentFont = False
      ReadOnly = True
      TabOrder = 0
      WantReturns = False
      OnClick = Memo1Click
    end
    object Memo5: TMemo
      Left = 67
      Top = 32
      Width = 38
      Height = 21
      Cursor = crArrow
      TabStop = False
      Color = clNavy
      Ctl3D = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 0
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentCtl3D = False
      ParentFont = False
      ReadOnly = True
      TabOrder = 1
      WantReturns = False
      OnClick = Memo1Click
    end
    object Memo6: TMemo
      Left = 67
      Top = 55
      Width = 38
      Height = 21
      Cursor = crArrow
      TabStop = False
      Color = clYellow
      Ctl3D = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 0
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentCtl3D = False
      ParentFont = False
      ReadOnly = True
      TabOrder = 2
      WantReturns = False
      OnClick = Memo1Click
    end
    object Memo7: TMemo
      Left = 107
      Top = 55
      Width = 38
      Height = 21
      Cursor = crArrow
      TabStop = False
      Color = clYellow
      Ctl3D = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 0
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentCtl3D = False
      ParentFont = False
      ReadOnly = True
      TabOrder = 3
      WantReturns = False
      OnClick = Memo1Click
    end
  end
  object ToolBar1: TToolBar
    Left = 8
    Top = 35
    Width = 141
    Height = 21
    Align = alNone
    AutoSize = True
    ButtonHeight = 21
    ButtonWidth = 47
    Caption = 'ToolBar1'
    EdgeBorders = []
    Flat = True
    ShowCaptions = True
    TabOrder = 3
    object ToolButton1: TToolButton
      Left = 0
      Top = 0
      Caption = 'Copy'
      ImageIndex = 0
    end
    object ToolButton2: TToolButton
      Left = 47
      Top = 0
      Caption = 'Rename'
      ImageIndex = 1
    end
    object ToolButton3: TToolButton
      Left = 94
      Top = 0
      Caption = 'Delete'
      ImageIndex = 2
    end
  end
  object ColorDialog: TColorDialog
    Left = 104
    Top = 224
  end
end
