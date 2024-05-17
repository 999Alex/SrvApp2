object frmMain: TfrmMain
  Left = 269
  Top = 190
  Width = 737
  Height = 453
  Caption = 'frmMain'
  Color = clBtnFace
  Enabled = False
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object memoLog: TMemo
    Left = 0
    Top = 33
    Width = 721
    Height = 382
    Align = alClient
    ScrollBars = ssBoth
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 721
    Height = 33
    Align = alTop
    TabOrder = 1
    object Button1: TButton
      Left = 16
      Top = 5
      Width = 75
      Height = 25
      Caption = 'Button1'
      TabOrder = 0
      Visible = False
    end
  end
  object Clt: TIdTCPClient
    MaxLineAction = maException
    ReadTimeout = 5000
    Port = 0
    Left = 72
    Top = 40
  end
  object ApplicationEvents1: TApplicationEvents
    OnMessage = ApplicationEvents1Message
    Left = 16
    Top = 40
  end
  object IdHTTP1: TIdHTTP
    MaxLineAction = maException
    ReadTimeout = 0
    OnConnected = IdHTTP1Connected
    AllowCookies = True
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = -1
    Request.ContentRangeStart = -1
    Request.ContentType = 'text/html'
    Request.Accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    HTTPOptions = [hoForceEncodeParams]
    Left = 112
    Top = 40
  end
end
