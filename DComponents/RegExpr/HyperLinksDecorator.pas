{$B-}
unit HyperLinksDecorator;

{
 Example of using TRegExpr:

 Functions to decorate hyper-links while converting plain
 text into HTML.

 For example, replaces 'http://anso.da.ru' with
 '<a href="http://anso.da.ru">anso.da.ru</a>'
 or 'anso@mail.ru' with '<a href="mailto:anso@mail.ru">anso@mail.ru</a>'.

 Note:
  This functions have to be optimized - they construct result strings
  with step by step concatenation that can take a lot of resources while
  processing big input texts with many hyper links.

 (c) 2000 Andrey V. Sorokin
  St-Petersburg
  Russia
  anso@mail.ru, anso@usa.net
  http://anso.da.ru
  http://anso.virtualave.net
}

interface

uses
 RegExpr;

type
TDecorateURLsFlags = (
 // describes, which parts of hyper-link must be included
 // into VISIBLE part of the link:
  durlProto, // Protocol (like 'ftp://' or 'http://')
  durlAddr,  // TCP address or domain name (like 'anso.da.ru')
  durlPort,  // Port number if specified (like ':8080')
  durlPath,  // Path to document (like 'index.htm')
  durlBMark, // Book mark (like '#mark')
  durlParam  // URL params (like '?ID=2&User=13')
 );

TDecorateURLsFlagSet = set of TDecorateURLsFlags;

function DecorateURLs (
 // can find hyper links like 'http://...' or 'ftp://..'
 // as well as links without protocol, but start with 'www.'
 // If You want to decorate emails as well, You have to use
 // function DecorateEMails
 const AText : string;
 // Input text to find hyper-links
  AFlags : TDecorateURLsFlagSet = [durlAddr, durlPath]
 // Which part of hyper-links found must be included into visible
 // part of URL, for example if [durlAddr] then hyper link
 // 'http://anso.da.ru/index.htm' will be decorated as
 // '<a href="http://anso.da.ru/index.htm">anso.da.ru</a>'
  ) : string;
 // Returns input text with decorated hyper links

function DecorateEMails (
 // Replaces all syntax correct e-mails
 // with '<a href="mailto:ADDR">ADDR</a>'
 // For example, replaces 'anso@mail.ru'
 // with '<a href="mailto:anso@mail.ru">anso@mail.ru</a>'.
 const AText : string
 // Input text to find e-mails
  ) : string;
 // Returns input text with decorated e-mails


implementation

uses
 SysUtils; // we are using AnsiCompareText

function DecorateURLs (const AText : string;
  AFlags : TDecorateURLsFlagSet = [durlAddr, durlPath]
  ) : string; 
const 
  URLTemplate = 
   '(?i)' 
   + '(' 
   + '(FTP|HTTP)://' // Protocol 
   + '|www\.)' // trick to catch links without protocol (like 'www.paycash.ru')
   + '([\w\d\-]+(\.[\w\d\-]+)+)' // TCP addr / domain name
   + '(:\d\d?\d?\d?\d?)?' // port number
   + '(((/[%+\w\d\-\\\.]*)+)*)' // unix path
   + '(\?[^\s=&]+=[^\s=&]+(&[^\s=&]+=[^\s=&]+)*)?' // request params
   + '(#[\w\d\-%+]+)?'; // bookmark
var
  PrevPos : integer;
  s, Proto, Addr, HRef : string;
begin
  Result := ''; 
  PrevPos := 1; 
  with TRegExpr.Create do try 
     Expression := URLTemplate; 
     if Exec (AText) then 
      REPEAT 
        s := ''; 
        if AnsiCompareText (Match [1], 'www.') = 0 then begin
           Proto := 'http://';
           Addr := Match [1] + Match [3]; 
           HRef := Proto + Match [0];
          end
         else begin 
           Proto := Match [1]; 
           Addr := Match [3]; 
           HRef := Match [0]; 
          end; 
        if durlProto in AFlags 
         then s := s + Proto; // Match [1] + '://'; 
        if durlAddr in AFlags 
         then s := s + Addr; // Match [2]; 
        if durlPort in AFlags 
         then s := s + Match [5]; 
        if durlPath in AFlags 
         then s := s + Match [6]; 
        if durlParam in AFlags 
         then s := s + Match [9]; 
        if durlBMark in AFlags
         then s := s + Match [11]; 
        Result := Result + System.Copy (AText, PrevPos, 
         MatchPos [0] - PrevPos) + '<a href="' + HRef + '">' + s + ''; 
        PrevPos := MatchPos [0] + MatchLen [0]; 
      UNTIL not ExecNext; 
     Result := Result + System.Copy (AText, PrevPos, MaxInt); // Tail 
    finally Free; 
   end; 
end; { of function DecorateURLs
--------------------------------------------------------------}

function DecorateEMails (const AText : string) : string;
 const
  MailTemplate =
   '[_a-zA-Z\d\-\.]+@[_a-zA-Z\d\-]+(\.[_a-zA-Z\d\-]+)+';
 var
  PrevPos : integer;
 begin
  Result := '';
  PrevPos := 1;
  with TRegExpr.Create do try
     Expression := MailTemplate;
     if Exec (AText) then
      REPEAT
        Result := Result + System.Copy (AText, PrevPos,
         MatchPos [0] - PrevPos) + '<a href="mailto:' + Match [0] + '">' + Match [0] + '</a>';
        PrevPos := MatchPos [0] + MatchLen [0];
      UNTIL not ExecNext;
     Result := Result + System.Copy (AText, PrevPos, MaxInt); // Tail
    finally Free;
   end;
 end; { of function DecorateEMails
--------------------------------------------------------------}

{
Note, that You can easely extract any part of URL (see AFlags parameter).
}

end.
