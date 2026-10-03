unit NiceSplitter;

interface

uses
  SysUtils, Classes, Controls, ExtCtrls;

type
  TNiceSplitter = class(TSplitter)
  published
    property OnDblClick;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Additional', [TNiceSplitter]);
end;

end.

