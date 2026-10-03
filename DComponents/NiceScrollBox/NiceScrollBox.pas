unit NiceScrollBox;

interface

uses
    Classes, SysUtils, Controls, Forms, Windows, Messages;

// This unit contains a TScrollBox ancestor that:
{
  - Tracks changes of thumb position and fires OnHorzScrollPosChanged and OnVertScrollPosChanged events.
  - Supports scrolling by mouse move in client area.
}


type

    TNiceScrollBox = class( TScrollBox )

    private
      FOnVertScrollPosChanged: TNotifyEvent;
      FOnHorzScrollPosChanged: TNotifyEvent;

      procedure WMHScroll( var Message: TWMHScroll ); message WM_HSCROLL;
      procedure WMVScroll( var Message: TWMVScroll ); message WM_VSCROLL;

    protected
      procedure DoVertScrollPosChanged; virtual;
      procedure DoHorzScrollPosChanged; virtual;

    published
      property OnVertScrollPosChanged: TNotifyEvent read FOnVertScrollPosChanged write FOnVertScrollPosChanged;
      property OnHorzScrollPosChanged: TNotifyEvent read FOnHorzScrollPosChanged write FOnHorzScrollPosChanged;
    end;


  procedure Register;


implementation



  procedure Register;

  begin
    RegisterComponents('Additional', [TNiceScrollBox]);
  end;



  procedure TNiceScrollBox.DoHorzScrollPosChanged;

  begin
    if Assigned(OnHorzScrollPosChanged) then
      OnHorzScrollPosChanged( Self );
  end;



  procedure TNiceScrollBox.DoVertScrollPosChanged;

  begin
    if Assigned(OnVertScrollPosChanged) then
      OnVertScrollPosChanged( Self );
  end;



  procedure TNiceScrollBox.WMHScroll( var Message: TWMHScroll );

  begin
    inherited;
    if (Message.ScrollBar = 0) and HorzScrollBar.Visible then
      DoHorzScrollPosChanged;
  end;



  procedure TNiceScrollBox.WMVScroll( var Message: TWMVScroll );

  begin
    inherited;

    if (Message.ScrollBar = 0) and VertScrollBar.Visible then
      DoVertScrollPosChanged;
  end;



end.

