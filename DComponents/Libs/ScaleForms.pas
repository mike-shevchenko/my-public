unit ScaleForms;

{ Michael Shevchenko <mikeshevchen@hotmail.com>, Moscow, 2003 }

interface


  uses
    Forms;



  { Typical parameter values }
  const
    SmallFontsPixelsPerInch = 96;
    SmallFontsNormalCaptionHeight = 19;
    SmallFontsToolWinCaptionHeight = 16;
    LargeFontsPixelsPerInch = 120;
    LargeFontsNormalCaptionHeight = 24;
    LargeFontsToolWinCaptionHeight = 20;



  procedure ScaleForm ( Form: TForm;
                        DesignedPixelsPerInch:        Integer = SmallFontsPixelsPerInch;
                        DesignedNormalCaptionHeight:  Integer = SmallFontsNormalCaptionHeight;
                        DesignedToolWinCaptionHeight: Integer = SmallFontsToolWinCaptionHeight );
  {
    Apply the procedure to a form in OnCreate to make it adjusted for possibly different system font size.
    The form should have Scaled = False.

    The parameters reflect Windows settings at COMPILE TIME:
    DesignedNormalCaptionHeight should be set to Appearance.WindowHeader + 1,
    DesignedToolWinCaptionHeight should be set to Appearance.ToolWindowHeader + 1,
    DesignedPixelsPerInch should be set to 96 for SmallFonts and 120 for LargeFonts.
    Default parameter values suit for compile-time SmallFonts with standard (non-XP) Appearance settings.

    NOTE that this technique was NOT tested with components that have AutoSize = True.
  }



implementation



  uses
    Windows, Controls, Classes;



  procedure ScaleForm ( Form: TForm;
                        DesignedPixelsPerInch:        Integer = SmallFontsPixelsPerInch;
                        DesignedNormalCaptionHeight:  Integer = SmallFontsNormalCaptionHeight;
                        DesignedToolWinCaptionHeight: Integer = SmallFontsToolWinCaptionHeight );

  var
    DesignedCaptionHeight: Integer;



    function Scale ( Value: Integer ): Integer;
    begin
      Result := MulDiv (Value, Screen.PixelsPerInch, DesignedPixelsPerInch);
    end;



    procedure ScaleControl ( Control: TControl );

      procedure ScaleWidthHeight;
      begin
        if (Control is TCustomForm) and (TCustomForm(Control).BorderStyle <> bsNone) then
        begin
          Control.ClientWidth  := Scale (Control.ClientWidth);
          Control.ClientHeight := Scale (Control.Height - DesignedCaptionHeight - 8);
        end
        else
        begin
          Control.Width  := Scale (Control.Width);
          Control.Height := Scale (Control.Height);
        end;
      end;

    var
      I: Integer;
      StoreOnResize, StoreOnCanResize, StoreOnConstrainedResize: Pointer;

    begin
      with TForm(Control) do  // NOTE:  Typecast here is safe because it is used to access protected members.
      begin
        StoreOnResize := @OnResize;
        @OnResize := nil;
        StoreOnCanResize := @OnCanResize;
        @OnCanResize := nil;
        StoreOnConstrainedResize := @OnConstrainedResize;
        @OnConstrainedResize := nil;
      end;

      with Control do
      begin
        if Screen.PixelsPerInch > DesignedPixelsPerInch then
        begin
          Constraints.MaxWidth  := Scale (Constraints.MaxWidth);
          Constraints.MaxHeight := Scale (Constraints.MaxHeight);

          ScaleWidthHeight;

          Constraints.MinWidth  := Scale (Constraints.MinWidth);
          Constraints.MinHeight := Scale (Constraints.MinHeight);
        end
        else
        begin
          Constraints.MinWidth  := Scale (Constraints.MinWidth);
          Constraints.MinHeight := Scale (Constraints.MinHeight);

          ScaleWidthHeight;

          Constraints.MaxWidth  := Scale (Constraints.MaxWidth);
          Constraints.MaxHeight := Scale (Constraints.MaxHeight);
        end;

        Left := Scale (Left);
        Top  := Scale (Top);

        for I := 0 to ComponentCount-1 do
          if Components[I] is TControl then
            ScaleControl (TControl(Components[I]));
      end;

      with TForm(Control) do  // NOTE:  See note above.
      begin
        @OnResize := StoreOnResize;
        @OnCanResize := StoreOnCanResize;
        @OnConstrainedResize := StoreOnConstrainedResize;
      end;
    end;



    procedure EnableWinControlAlign ( WinControl: TWinControl );
    var
      I: Integer;
    begin
      WinControl.ControlState := WinControl.ControlState - [csAlignmentNeeded];
      WinControl.EnableAlign;
      with WinControl do
        for I := 0 to ComponentCount-1 do
          if Components[I] is TWinControl then
            EnableWinControlAlign (TWinControl(Components[I]));
    end;



    procedure DisableWinControlAlign ( WinControl: TWinControl );
    var
      I: Integer;
    begin
      with WinControl do
        for I := 0 to ComponentCount-1 do
          if Components[I] is TWinControl then
            DisableWinControlAlign (TWinControl(Components[I]));
      WinControl.DisableAlign;
    end;



    // NOTE:  See note below.
    procedure RequestClientRect ( WinControl: TWinControl );
    var
      I: Integer;
      Rect: TRect;
    begin
      Windows.GetClientRect (WinControl.Handle, Rect);

      with WinControl do
        for I := 0 to ComponentCount-1 do
          if Components[I] is TWinControl then
            RequestClientRect (TWinControl(Components[I]));
    end;



  begin
    // NOTE:  This code is a workaround for a VCL bug with forms having Scaled = False.
    if Screen.PixelsPerInch = DesignedPixelsPerInch then
    begin
      Form.DisableAlign;
      RequestClientRect (Form);
      Form.EnableAlign;
      Exit;
    end;

    if Form.BorderStyle in [bsToolWindow, bsSizeToolWin] then
      DesignedCaptionHeight := DesignedToolWinCaptionHeight
    else
      DesignedCaptionHeight := DesignedNormalCaptionHeight;

    DisableWinControlAlign (Form);
    ScaleControl (Form);
    EnableWinControlAlign (Form);
  end;



end.


