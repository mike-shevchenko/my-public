unit NicePanel;

interface

  uses
    Windows, Classes, Graphics, Controls,
    ExtCtrls;

  type
    TNicePanel = class ( TPanel )
    private
      FBevelDeep: Boolean;
      procedure SetBevelDeep ( Value: Boolean );
    protected
      procedure Paint; override;
    public
      constructor Create ( AOwner: TComponent );  override;
    published
      property BevelWidth default 2;
      property BevelDeep: Boolean  read FBevelDeep  write SetBevelDeep  default True;
    end;


  procedure Register;



implementation


  procedure Register;
  begin
    RegisterComponents('Additional', [TNicePanel]);
  end;



  constructor TNicePanel.Create ( AOwner: TComponent );
  begin
    inherited Create (AOwner);
    BevelWidth := 2;
    BevelDeep := True;
  end;



  procedure TNicePanel.SetBevelDeep ( Value: Boolean );
  begin
    if FBevelDeep = Value then Exit;
    FBevelDeep := Value;
    Invalidate;
  end;



  procedure TNicePanel.Paint;
  var
    Rect: TRect;
    B, W: Integer;
  begin
    inherited Paint;
    if not FBevelDeep then Exit;
    Rect := ClientRect;
    W := BevelWidth;
    B := BorderWidth;

    if BevelOuter = bvRaised then
    begin
      Frame3D (Canvas, Rect, cl3DLight, cl3DDkShadow, 1);
      InflateRect(Rect, -(W-1), -(W-1));
    end
    else if BevelOuter = bvLowered then
    begin
      InflateRect(Rect, -(W-1), -(W-1));
      Frame3D (Canvas, Rect, cl3DDkShadow, cl3DLight, 1);
    end;

    InflateRect (Rect, -B, -B);

    if BevelInner = bvRaised then
      Frame3D (Canvas, Rect, cl3DLight, cl3DDkShadow, 1)
    else if BevelInner = bvLowered then
    begin
      InflateRect(Rect, -(W-1), -(W-1));
      Frame3D (Canvas, Rect, cl3DDkShadow, cl3DLight, 1);
    end;
  end;


end.


