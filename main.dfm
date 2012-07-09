object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 108
  ClientWidth = 780
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 471
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Start'
    TabOrder = 0
    OnClick = Button1Click
  end
  object ProgressBar1: TProgressBar
    Left = 8
    Top = 39
    Width = 764
    Height = 17
    TabOrder = 1
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 89
    Width = 780
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object ProgressBar2: TProgressBar
    Left = 8
    Top = 62
    Width = 764
    Height = 17
    TabOrder = 3
  end
  object CheckBox1: TCheckBox
    Left = 584
    Top = 8
    Width = 97
    Height = 17
    Caption = 'Stop'
    TabOrder = 4
  end
end
