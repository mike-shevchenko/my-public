unit CommonUtils;

interface

  uses
    Classes, Windows, TntClasses, ADODB_TLB, Variants, Contnrs, SysUtils,
    RegExpr, XMLObjects;



  // получить только имя файла без расширения
  function ExtractOnlyFilename( FullFilename: WideString ): WideString;


  // стандартные диалоги
  procedure ShowGeneralError( const Pref: WideString;  const Msg: WideString = '';  Para: Boolean = True );
  procedure ShowGeneralInfo ( const Msg: WideString );
  function  AskGeneralQuestion ( const Msg: WideString;  Opt: Integer = MB_YESNOCANCEL;
    Icon: Integer = MB_ICONQUESTION ): Integer;

  // быстрый поиск символа в строке
  function  WideCharPos ( const S: WideString;  const Ch: WideChar;  const Index: Integer ): Integer;  //az
  function WidePosEx( const Substr, Str: WideString;  Start: Integer = 1 ): Integer;

  // поиск в сортированном списке
  function FindInSortedList( List: TList;  Item: Pointer;  var Index: Integer ): Boolean;

  // работа со списками, разделёнными запятыми:
  // ------
  //   разбивает список на токены, разделителем является символ ','; повторение разделителя является
  //   escape-символом, приравнивается к тексту ','
  procedure CommaTextToList ( const S: WideString;  L: TTntStringList );
  function  CommaTextToRE ( const S: WideString ): WideString;
  function  EscapedText ( const S: WideString ): WideString;

  // возвращает Logon-имя текущего пользователя
  function  GetCurrentUser: WideString;

  // считывает строчку из БД
  // ------
  //   если S = Null, то в результате получается пустая строка. В противном случае пытается извлечь из S
  //   строку. Если этот вариант содержит не строку, то генерируется исключение
  function DBString( const S: OleVariant ): WideString;
  function DBAnsiString( const S: OleVariant ): AnsiString;

  // заполняет список L установленными TrueType шрифтами на системе
  procedure GetTrueTypeFonts ( L: TTntStrings );

  procedure CheckDelphiName( const Name: WideString ); overload;
  procedure CheckDelphiName( List: TXMLNamedObjectList ); overload;

  type
    TString = AnsiString;

  procedure TStringToWideString( const S: TString;  var Result: WideString );
  procedure WideStringToTString( const S: WideString;  var Result: TString );

  // Заменяет во входной цепочке коды символов $XXXX на сами символы.
  function SymbolCodesToSymbols ( const S: WideString ): WideString;

type

  TCheckMethod = procedure of object;

  function CheckToIs(CheckMethod: TCheckMethod): Boolean;
  function CheckToIsWithMessage(CheckMethod: TCheckMethod): Boolean;

  type

    //==================================================================================================================
    // Base class for all errors.
    //------------------------------------------------------------------------------------------------------------------

    EBaseError = class(Exception)

    private
      FPosition: Integer;
      FError: string;
      FCategory: string;
      FSource: WideString;
      FMessage: WideString;

    protected
      procedure UpdateMessage; virtual;

    public
      constructor Create(const Error: string;  const Source: WideString = ''; Position: Integer = 1;
        Category: string = '');

      property Error:    string     read FError;    // ID of an error.
      property Source:   WideString read FSource;   // Erroneous string.
      property Position: Integer    read FPosition; // 1-based error position in Source.
      property Category: string     read FCategory; // Category of the error.
      property Message:  WideString read FMessage;  // Full message text.
    end;

    //==================================================================================================================
    // Вызов хранимых процедур сервера БД
    // -----
    //   Вызов осуществляется с помощью объекта ADO.Command, который создаётся при создании объекта данного
    //   класса и уничножается в деструкторе. После создания объекта, нужно либо инициализировать свойство
    //   ActiveConnection (в этом случае используется существующее подключение), либо ConnectionString (в
    //   этом случае создаётся новое соединение с БД).
    //   Запуск хранимых процедур возможен в следующих вариантах:
    //     - с параметрами / без параметров
    //     - с возвратом объекта Recordset / без возврата объекта Recordset

    TADOStoredProc = class
    private
      FCmd: Command;
      FOwnConnection: Boolean;

      procedure SetConnectionString(const Value: WideString);
      function  GetConnectionString: WideString;
      procedure SetActiveConnection(const Value: Connection);
      function  GetActiveConnection: Connection;

      // удаление предыдущих параметров хранимой процедуры. Необходимо производить перед каждым запуском,
      // иначе выбрасывается исключение о несоответствии типов или количества параметров
      procedure DeleteParams;

    public
      constructor Create; virtual;

      destructor Destroy; override;

      procedure ExecuteStoredProc ( const Name: WideString;  const Params: Variant ); overload;
      procedure ExecuteStoredProc ( const Name: WideString ); overload;

      function  QueryStoredProc ( const Name: WideString;  const Params: Variant ): Recordset; overload;
      function  QueryStoredProc ( const Name: WideString ): Recordset; overload;

      property ConnectionString: WideString read GetConnectionString write SetConnectionString;
      property ActiveConnection: Connection read GetActiveConnection write SetActiveConnection;
      property Cmd: Command read FCmd;
    end;


    //==================================================================================================================
    // Типизированный поток
    // -----
    //   Имеет возможность записывать / считывать из потока стандартные типы данных, а не произвольный буфер
    //

    TTypedStream = class
    private
      FStream: TStream;
      FOwnsStream: Boolean;

      procedure SetStream( AStream: TStream );

    public
      constructor Create ( AStream: TStream = nil;  AOwnsStream: Boolean = True ); virtual;
      destructor Destroy; override;

      function  ReadInteger: Integer; overload;
      procedure ReadInteger( var Result: Integer ); overload;
      procedure ReadInteger( var Result: Int64 ); overload;
      function  ReadSmallInteger: Integer;
      function  ReadWideString: WideString;
      procedure ReadWideStringVar ( var Result: WideString );
      function  ReadAnsiString: AnsiString;
      procedure ReadAnsiStringVar ( var Result: AnsiString );

      procedure WriteInteger( Value: Integer ); overload;
      procedure WriteInteger( Value: Int64 ); overload;
      procedure WriteSmallInteger( Value: Integer );
      procedure WriteWideString( const Value: WideString );
      procedure WriteAnsiString( const Value: AnsiString );

      procedure ReadString( var Result: AnsiString ); overload;
      procedure ReadString( var Result: WideString ); overload;

      procedure WriteString( const Value: WideString ); overload;
      procedure WriteString( const Value: AnsiString ); overload;

      property Stream: TStream read FStream write SetStream;
      property OwnsStream: Boolean read FOwnsStream write FOwnsStream;
    end;


    //==================================================================================================================
    // Поток, вычисляющий размер записанных данных в байтах
    // -----
    //

    TMeasureStream = class(TStream)
    private
      FDataSize: Integer;

    public
      function Write( const Buffer;  Count: Longint ): Longint; override;
      function Read( var Buffer; Count: Longint ): Longint; override;

      property DataSize: Integer read FDataSize;
    end;


    //==================================================================================================================
    // Поддержка типа данных SQL-сервера nvarchar
    // -----
    //   В переменную типа nvarchar может передаваться не более 4000 символов
    //

  const
    MaxVarCharCount = 4000;  // максимальное количество символов, передаваемых в nvarchar

  type
    TVarChar = class
    private
      FBuffer:   WideString;
      FMaxCount: Integer;
      FOverflow: Boolean;
      FCurCount: Integer;

      function GetValue: WideString;
      function GetIsEmpty: Boolean;

    public
      constructor Create ( AMaxCount: Integer = MaxVarCharCount );

      procedure Add ( const S: WideString );

      procedure Reset;

      property Value:    WideString read GetValue;
      property MaxCount: Integer    read FMaxCount;
      property Overflow: Boolean    read FOverflow;
      property IsEmpty:  Boolean    read GetIsEmpty;
    end;



    //==================================================================================================================
    // Сортированный по указателю список объектов
    // -----
    //

    TSortedList = class(TList)
    private
      procedure QuickSort ( L, R: Integer );

    public
      procedure Sort;

      function Find ( Obj: Pointer;  var Index: Integer ): Boolean;
      function Contains ( Obj: Pointer ): Boolean;
      procedure AddSorted ( Obj: Pointer );
    end;



    //==================================================================================================================
    // Интервал целых чисел
    // -----
    //

    TIntInterval = class
    private
      FLeft:  Integer;
      FRight: Integer;

      procedure Init ( ALeft, ARight: Integer ); overload;
      procedure Init ( Value: Integer ); overload;

    public
      constructor CreateFromString ( const S: WideString );
      constructor Create ( ALeft, ARight: Integer ); overload;
      constructor Create ( Value: Integer ); overload;

      function Contains ( Value: Integer ): Boolean;

      property Left:  Integer read FLeft;
      property Right: Integer read FRight;
    end;



    //==================================================================================================================
    // Список интервалов целых чисел
    // -----
    //

    TIntIntervalList = class
    private
      FList: TObjectList;

    public
      constructor CreateFromString ( const S: WideString );
      destructor Destroy; override;

      function Contains ( Value: Integer ): Boolean;
    end;



    //==================================================================================================================
    // Список интервалов целых чисел
    // -----
    //

    TRegExprChecker = class
    private
      FTester: TRegExpr;
      FLastError: WideString;
      FLastPos: Integer;
      FHasError: Boolean;

      function GetExpresstion: WideString;
      procedure SetExpression(const Value: WideString);
      function  GetErrorMsg ( ErrCode: Integer ): WideString;

    public
      constructor Create; virtual;
      destructor Destroy; override;

      procedure Flush;

      property HasError: Boolean read FHasError;
      property LastError: WideString read FLastError;
      property LastPos:   Integer read FLastPos;
      property Expression: WideString read GetExpresstion write SetExpression;
      property RegExpr: TRegExpr read FTester;
    end;


    //==================================================================================================================
    // Блокировки для БД
    // -----
    //

    TDBLocker = class
    private
      FCmd: TADOStoredProc;
      FDomainID, FPropID: Integer;
      FLockFree: Boolean;
      FLockHost: WideString;
      FLockUser: WideString;
      FLockTime: TDateTime;

      procedure SetLockInfo ( RS: Recordset );

    public
      constructor Create ( ACmd: TADOStoredProc;  ADomainID, APropID: Integer );

      procedure Lock ( ObjID: Integer );
      procedure UnLock ( ObjID: Integer );
      procedure CheckLock ( ObjID: Integer );

      function IsLocked ( ObjID: Integer ): Boolean;

      property LockFree: Boolean read FLockFree;
      property LockHost: WideString read FLockHost;
      property LockUser: WideString read FLockUser;
      property LockTime: TDateTime read FLockTime;
    end;


    //==================================================================================================================
    // Enhanced thread
    // -----
    //

    TThreadState =
    (
      cThreadState_None,
      cThreadState_InWork,
      cThreadState_Done,
      cThreadState_Error,
      cThreadState_Terminated
    );


    EThreadError = class(Exception)
    private
      FMessage: WideString;

    public
      constructor Create( const Message: WideString );

      property Message: WideString read FMessage;
    end;



    TCommonThread = class(TThread)
    private
      FState: TThreadState;
      FError: EThreadError;

    protected
      procedure Execute; override;
      procedure DoExecute; virtual; abstract;

    public
      destructor Destroy; override;

      procedure Terminate; virtual;

      property State: TThreadState read FState;
      property Error: EThreadError read FError;
    end;

    TAsyncMethodThread = class;
    TAsyncMethod = procedure ( Thread: TAsyncMethodThread ) of object;

    TAsyncMethodThread = class( TCommonThread )
    private
      FMethod: TAsyncMethod;

    protected
      procedure DoExecute; override;

    public
      constructor Create( Method: TAsyncMethod;  CreateSuspended: Boolean );
    end;


    //==================================================================================================================
    // Объект, сохраняемый и загружаемый в файл
    // -----
    //

  const
    cFiledObjectAction_Idle = 0;
    cFiledObjectAction_Load = 1;
    cFiledObjectAction_Save = 2;

  type
    TFiledObject = class;
    TFiledObjectAction = Integer;

    TFiledObjectActionInit = procedure ( Sender: TFiledObject;  Action: TFiledObjectAction ) of object;
    // step iterates from 1 to 100
    TFiledObjectActionStep = procedure ( Sender: TFiledObject;  Action: TFiledObjectAction;  Step: Integer ) of object;
    TFiledObjectActionDone = procedure ( Sender: TFiledObject;  Action: TFiledObjectAction;  State: TThreadState;
                                         Error: EThreadError ) of object;

    //
    // Объект может находиться в одном из следующих состояний:
    //  - не инициализирован
    //  - новый
    //  - сохранённый
    //
    // Дополнительные флаги:
    //  - сохранён/изменён (не применим к режиму не инициализирован)
    //  - только для чтения
    //  - выполняется асинхронная процедура
    //

    TFiledObjectState =
    (
      cFiledObjectState_Closed,
      cFiledObjectState_New,
      cFiledObjectState_Normal
    );

    TSyncMethod = procedure of object;


    TFiledObject = class
    private
      FFullName: WideString;
      FOldFullName: WideString;
      FAction: TFiledObjectAction;
      FState: TFiledObjectState;
      FThread: TCommonThread;
      FModified: Boolean;
      FReadOnly: Boolean;
      FOnActionInit: TFiledObjectActionInit;
      FOnActionStep: TFiledObjectActionStep;
      FOnActionDone: TFiledObjectActionDone;
      FOnModified: TNotifyEvent;
      FPendingModified: Boolean;

      FStep: Integer;
      FTotal: Integer;
      FPosition: Integer;
      FOnChange: TNotifyEvent;

      function GetFileName: WideString;
      function GetRunningAsyncAction: Boolean;
      procedure SetModified(const Value: Boolean);
      procedure SetReadOnly(const Value: Boolean);

      procedure SetPosition(const Value: Integer);
      procedure SetTotal(const Value: Integer);
      procedure SetStep(const Value: Integer);
      procedure SyncDoStep;

      procedure AsyncLoad( Thread: TAsyncMethodThread );
      procedure AsyncSave( Thread: TAsyncMethodThread );

    protected
      function GetDisplayName: WideString; virtual;
      procedure ModifiedChange; virtual;

      procedure DoNew; virtual; abstract;
      procedure DoLoad; virtual; abstract;
      procedure DoSave; virtual; abstract;
      procedure DoClose; virtual; abstract;
      procedure ThreadTerminate( Sender: TObject );

      procedure DoActionDone( Action: TFiledObjectAction;  State: TThreadState;  Error: EThreadError ); virtual;
      procedure DoModified; virtual;

    public
      constructor Create; virtual;
      destructor Destroy; override;

      procedure New;
      procedure Load( AFileName: WideString;  Async: Boolean = False );
      procedure Save( AFileName: WideString;  Async: Boolean = False );
      procedure Close;

      procedure CancelAsyncAction;
      procedure InitAsyncAction( Action: TFiledObjectAction;  Method: TAsyncMethod ); overload;
      procedure InitAsyncAction( Action: TFiledObjectAction;  Thread: TCommonThread ); overload;
      procedure InitSyncAction( Action: TFiledObjectAction;  Method: TSyncMethod );

      function NeedSave: Boolean; virtual;

      property FileName: WideString read GetFileName;
      property FullName: WideString read FFullName;
      property DisplayName: WideString read GetDisplayName;

      property State: TFiledObjectState read FState;
      property Modified: Boolean read FModified write SetModified;
      property ReadOnly: Boolean read FReadOnly write SetReadOnly;
      property RunningAsyncAction: Boolean read GetRunningAsyncAction;

      property Action: TFiledObjectAction read FAction;
      property Thread: TCommonThread read FThread;
      property Step: Integer read FStep write SetStep;
      property Total: Integer read FTotal write SetTotal;
      property Position: Integer read FPosition write SetPosition;

      property OnChange: TNotifyEvent read FOnChange write FOnChange;
      property OnModified:   TNotifyEvent read FOnModified write FOnModified;
      property OnActionInit: TFiledObjectActionInit read FOnActionInit write FOnActionInit;
      property OnActionStep: TFiledObjectActionStep read FOnActionStep write FOnActionStep;
      property OnActionDone: TFiledObjectActionDone read FOnActionDone write FOnActionDone;
    end;

implementation

  uses
    Forms, TntSysUtils;

  const
    cStdLength = 80;



{Global functions}

  function SymbolCodesToSymbols ( const S: WideString ): WideString;

  type
    TState =
    (
      stStart,
      stWait,
      stSymbol,
      stHexSymbol,
      stDigit,
      stHexDigit,
      stDone,
      stMinus,
      stStopSymbol
    );

    TLetter =
    (
      ltDigit,
      ltSymbol,
      ltOther,
      ltHexSymbol,
      ltHexDigit,
      ltEnd,
      ltMinus,
      ltStopSymbol
    );

  var
    State:  TState;
    Letter: TLetter;
    PosI, PosR, LastI: Integer;


    procedure NextLetter;
    begin
      Inc (PosI);
      case S[PosI] of
        #0:
          Letter := ltEnd;
        '#':
          Letter := ltSymbol;
        '$':
          Letter := ltHexSymbol;
        '0'..'9':
          Letter := ltDigit;
        'A'..'F':
          Letter := ltHexDigit;
        '\':
          Letter := ltStopSymbol;
        '-':
          Letter := ltMinus;
      else
        Letter := ltOther;
      end;
    end;

  begin
    if S = '' then
    begin
      Result := '';
      Exit;
    end;

    PosI   := 0;
    PosR   := 0;
    LastI  := -1;  // Warning suppress
    State  := stStart;
    Result := S;

    while True do
    begin
      NextLetter;

      case State of
        stStart:
          case Letter of
            ltSymbol:
              State := stSymbol;
            ltEnd:
              Break;
            ltStopSymbol:
              State := stStopSymbol;
            ltHexSymbol:
              State := stStart;
          else
            State := stWait;
          end;

        stWait:
          begin
            Inc (PosR);
            Result[PosR] := S[PosI-1];

            case Letter of
              ltSymbol:
                State := stSymbol;
              ltEnd:
                Break;
              ltStopSymbol:
                State := stStopSymbol;
              ltHexSymbol:
                State := stStart;
            end;
          end;

        stStopSymbol:
          State := stWait;

        stSymbol:
          begin
            LastI := PosI;
            case Letter of
              ltHexSymbol:
                State := stHexSymbol;
              ltMinus:
                State := stMinus;
              ltDigit:
                State := stDigit;
            else
              State := stStart;
              Dec (PosI);
            end;
          end;

        stHexSymbol:
          begin
            case Letter of
              ltDigit, ltHexDigit:
                State := stHexDigit;
            else
              State := stStart;
              Dec (PosI);
            end;
          end;

        stMinus:
          if Letter = ltDigit then
            State := stDigit
          else
            State := stWait;

        stDigit:
          if Letter <> ltDigit then
            State := stDone;

        stHexDigit:
          if not (Letter in [ltDigit, ltHexDigit]) then
            State := stDone;

        stDone:
          begin
            Inc (PosR);
            Result[PosR] := WideChar(StrToInt(Copy(S, LastI, PosI-LastI-1)));
            Dec (PosI, 2);
            State := stStart;
          end;
      end;
    end;

    if PosI <> PosR then
      Result := Copy(Result, 1, PosR);
  end;



  function WidePosEx( const Substr, Str: WideString;  Start: Integer = 1 ): Integer;

  begin
    Result := Pos( Substr, Copy( Str, Start, MaxInt ) );
    if Result <> 0 then
      Inc( Result, Start - 1 );
  end;



  function ExtractOnlyFilename( FullFilename: WideString ): WideString;

  begin
    Result := WideString(ExtractFilename( FullFilename ));
    Result := Copy( Result, 1, Length(Result) - Length( ExtractFileExt(Result) ) ); // Remove extension.
  end;



  procedure TStringToWideString( const S: TString;  var Result: WideString );
  begin
    SetLength( Result, Length(S) div 2 );
    if Length(S) > 0 then
      Move( S[1], Result[1], Length(S) );
  end;



  procedure WideStringToTString( const S: WideString;  var Result: TString );
  begin
    SetLength( Result, Length(S) * 2 );
    if Length(Result) > 0 then
      Move( S[1], Result[1], Length(Result) );
  end;



  procedure CheckDelphiName( const Name: WideString );
  const
    cNameInit = ['_', 'A'..'Z', 'a'..'z'];
    cNameBody = cNameInit + ['0'..'9'];
  var
    I: Integer;
  begin
    // name must be delphi compatible

    // check for empty names
    if Name = '' then
      {raise error}Assert( False );
    // check initial character
    if (Hi(Ord(Name[1])) <> 0) or not (Chr(Lo(Ord(Name[1]))) in cNameInit) then
      {raise error}Assert( False );
    // check other characters
    for I := 2 to Length(Name) do
      if (Hi(Ord(Name[I])) <> 0) or not (Chr(Lo(Ord(Name[I]))) in cNameBody) then
        {raise error}Assert( False );
  end;



  procedure CheckDelphiName( List: TXMLNamedObjectList );
  var
    I: Integer;
  begin
    for I := 0 to List.Count-1 do
      CheckDelphiName( TXMLNamedObject(List[I]).Name );
  end;



  procedure ShowGeneralError( const Pref, Msg: WideString;  Para: Boolean );
  var
    Text, Title: WideString;
  begin
    Text := Pref;
    if Msg <> '' then
      if Para then
        Text := Text + #13#10 + Msg
      else
        Text := Text + ' ' + Msg;

    Text  := WideWrapText( Text, #13#10, [' ', '-'], cStdLength );
    Title := Application.Title;

    MessageBoxW( Application.Handle, PWideChar(Text), PWideChar(Title), MB_OK or MB_ICONSTOP );
  end;



  procedure ShowGeneralInfo ( const Msg: WideString );
  var
    Text, Title: WideString;
  begin
    Text  := WideWrapText( Msg, #13#10, [' ', '-', '\'], cStdLength );
    Title := Application.Title;

    MessageBoxW( Application.Handle, PWideChar(Text), PWideChar(Title), MB_OK or MB_ICONINFORMATION );
  end;



  function  AskGeneralQuestion ( const Msg: WideString;  Opt, Icon: Integer ): Integer;
  var
    Text, Title: WideString;
  begin
    Text  := WideWrapText( Msg, #13#10, [' ', '-', '\'], cStdLength );
    Title := Application.Title;

    Result := MessageBoxW( Application.Handle, PWideChar(Text), PWideChar(Title), Opt or Icon );
  end;


  function WideCharPos(const S: WideString; const Ch: WideChar; const Index: Integer): Integer;
  asm
         TEST    EAX,EAX        // make sure we are not null
         JZ      @@StrIsNil
         DEC     ECX            // make index zero based
         JL      @@IdxIsSmall
         PUSH    EBX
         PUSH    EDI
         MOV     EDI, EAX       // EDI := S
         XOR     EAX, EAX
         MOV     AX, DX         // AX := Ch
         MOV     EDX, [EDI - 4] // EDX := Length(S) * 2
         SHR     EDX, 1         // EDX := EDX div 2
         MOV     EBX, EDX       // save the length to calc. result
         SUB     EDX, ECX       // EDX = EDX - Index = # of chars to scan
         JLE     @@IdxIsBig
         SHL     ECX, 1         // two bytes per char
         ADD     EDI, ECX       // point to index'th char
         MOV     ECX, EDX       // loop counter
         REPNE   SCASW
         JNE     @@NoMatch
         MOV     EAX, EBX       // result := saved length -
         SUB     EAX, ECX       // loop counter value
         POP     EDI
         POP     EBX
         RET

       @@IdxIsBig:
       @@NoMatch:
         XOR     EAX,EAX
         POP     EDI
         POP     EBX
         RET

       @@IdxIsSmall:
         XOR     EAX, EAX
       @@StrIsNil:

  end;


  procedure CommaTextToList ( const S: WideString;  L: TTntStringList );
  var
    Last, Pos: Integer;


    procedure AddString;
    var
      Tmp: WideString;
    begin
      Tmp := Trim(Copy( S, Last+1, Pos-Last-1 ));
      if Tmp <> '' then
      begin
        Tmp := WideStringReplace( Tmp, ',,', ',', [rfReplaceAll] );
        L.Add( Tmp );
      end;
      Last := Pos;
      Inc( Pos );
    end;


  begin
    L.Clear;
    if S = '' then Exit;

    Last := 0;
    Pos  := 1;

    while True do
      case S[Pos] of
        ',':
          begin
            if S[Pos+1] = ',' then
              Inc( Pos, 2 )
            else
              AddString;
          end;

        #0:
          begin
            AddString;
            Break;
          end;
      else
        Inc( Pos );
      end;
  end;



  function EscapedText ( const S: WideString ): WideString;
  var
    I, J: Integer;
  const
    cMetaSmb = ['^', '$', '\', '.', '*', '+', '?', '|', '[', ']', '(', ')', '{', '}'];
  begin
    SetLength( Result, Length(S) * 2 );

    J := 0;
    for I := 1 to Length(S) do
    begin
      if (Hi(Integer(S[I])) = 0) and (Char(Lo(Integer(S[I]))) in cMetaSmb) then
      begin
        Inc( J );
        Result[J] := '\';
      end;
      Inc( J );
      Result[J] := S[I];
    end;
    Result := Copy( Result, 1, J );
  end;



  function  CommaTextToRE ( const S: WideString ): WideString;
  var
    L: TTntStringList;
    I: Integer;
  begin
    Result := '';
    L := TTntStringList.Create;
    try
      CommaTextToList( S, L );
      for I := 0 to L.Count-1 do
        if Result = '' then
          Result := EscapedText( L[I] )
        else
          Result := Result + '|' + EscapedText( L[I] );
      if Result <> '' then
        Result := '(?i)^(' + Result + ')$';
    finally
      L.Free;
    end;
  end;



  function  GetCurrentUser: WideString;
  var
    Buf: array[Byte] of WideChar;
    Count: Cardinal;
  begin
    Count  := SizeOf(Buf);
    if Windows.GetUserNameW( Buf, Count ) then
      Result := Buf
    else
      Result := '';
  end;



  function DBString( const S: OleVariant ): WideString;
  begin
    if VarIsNull(S) then
      Result := ''
    else
      Result := Trim(S);
  end;



  function DBAnsiString( const S: OleVariant ): AnsiString;
  begin
    if VarIsNull(S) then
      Result := ''
    else
      Result := Trim(S);
  end;



  function FindInSortedList( List: TList;  Item: Pointer;  var Index: Integer ): Boolean;
  var
    L, M, H: Integer;
  begin
    if List.Count = 0 then
    begin
      Result := False;
      Index  := 0;
      Exit;
    end;

    L := 0;
    H := List.Count - 1;

    while L <> H do
    begin
      M  := L + ((H - L) div 2);
      if List.List[M] = Item then
      begin
        Result := True;
        Index  := M;
        Exit;
      end;
      if Integer(List.List[M]) > Integer(Item) then
        H := M
      else
        L  := M + 1;
    end;

    if List.List[L] = Item then
    begin
      Index  := L;
      Result := True;
    end
    else if Integer(List.List[L]) > Integer(Item) then
    begin
      Index  := L;
      Result := False;
    end
    else
    begin
      Index  := List.Count;
      Result := False;
    end;
  end;



  function EnumFontFamExProc ( var LFData: TEnumLogFontExW;  PhFData: Pointer;  FontType: DWORD;  Data: LPARAM ): Integer; stdcall;
  var
    Name: WideString;
  begin
    if FontType = TRUETYPE_FONTTYPE then
    begin
      Name := LFData.elfLogFont.lfFaceName;
      if Name[1] = '@' then
        Name := Copy( Name, 2, MaxInt );
      with TTntStrings(Data) do
        if IndexOf( Name ) = -1 then
          Add( Name );
    end;
    Result := 1; // continue enumerate fonts
  end;

  

  procedure GetTrueTypeFonts ( L: TTntStrings );
  var
    DC: HDC;
    LF: TLogFontW;
  begin
    FillChar( LF, SizeOf(TLogFontW), 0 );
    LF.lfCharSet := DEFAULT_CHARSET;
    L.BeginUpdate;
    DC := GetDC(0);
    try
      EnumFontFamiliesExW( DC, LF, Pointer(@EnumFontFamExProc), Longint(Pointer(L)), 0 );
    finally
      L.EndUpdate;
      ReleaseDC( 0, DC );
    end;
  end;

{ TADOStoredProc }

  constructor TADOStoredProc.Create;
  begin
    inherited Create;
    FCmd := CoCommand.Create;
    FCmd.CommandType := adCmdStoredProc;
  end;



  procedure TADOStoredProc.DeleteParams;
  var
    I: Integer;
  begin
    for I := FCmd.Parameters.Count-1 downto 0 do
      FCmd.Parameters.Delete( I );
  end;



  destructor TADOStoredProc.Destroy;
  begin
    if FOwnConnection then
      with FCmd.Get_ActiveConnection do
        if State = adStateOpen then
          Close;
    inherited;
  end;



  procedure TADOStoredProc.ExecuteStoredProc(const Name: WideString);
  var
    Dummy1, Dummy2: OleVariant;
  begin
    VarCopy( Dummy1, EmptyParam );
    VarCopy( Dummy2, EmptyParam );
    Cmd.CommandText := Name;
    DeleteParams;
    Cmd.Execute( Dummy1, Dummy2, adCmdStoredProc + adExecuteNoRecords );
  end;



  procedure TADOStoredProc.ExecuteStoredProc(const Name: WideString; const Params: Variant);
  var
    Dummy1, Dummy2: OleVariant;
  begin
    VarCopy( Dummy1, EmptyParam );
    FCmd.CommandText := Name;
    Dummy2 := Params;
    DeleteParams;
    FCmd.Execute( Dummy1, Dummy2, adCmdStoredProc + adExecuteNoRecords );
  end;



  function TADOStoredProc.GetActiveConnection: Connection;
  begin
    Result := FCmd.Get_ActiveConnection;
  end;



  function TADOStoredProc.GetConnectionString: WideString;
  begin
    Result := ActiveConnection.ConnectionString;
  end;



  function TADOStoredProc.QueryStoredProc(const Name: WideString): Recordset;
  var
    Dummy1, Dummy2: OleVariant;
  begin
    VarCopy( Dummy1, EmptyParam );
    VarCopy( Dummy2, EmptyParam );
    Cmd.CommandText := Name;
    DeleteParams;

    Result := Cmd.Execute( Dummy1, Dummy2, adCmdStoredProc );
  end;



  function TADOStoredProc.QueryStoredProc(const Name: WideString;
    const Params: Variant): Recordset;
  var
    Dummy1, Dummy2: OleVariant;
  begin
    VarCopy( Dummy1, EmptyParam );
    Cmd.CommandText := Name;
    Dummy2 := Params;
    DeleteParams;
    Result := Cmd.Execute( Dummy1, Dummy2, adCmdStoredProc );
  end;



  procedure TADOStoredProc.SetActiveConnection(const Value: Connection);
  begin
    FCmd.Set_ActiveConnection( Value );
    FOwnConnection := False;
  end;



  procedure TADOStoredProc.SetConnectionString(const Value: WideString);
  begin
    FCmd.Set_ActiveConnection( Value );
    FOwnConnection := True;
  end;



{ TTypedStream }

  const
    cMaxSmallInt = $FF;

  constructor TTypedStream.Create(AStream: TStream; AOwnsStream: Boolean);
  begin
    inherited Create;
    FStream := AStream;
    FOwnsStream := AOwnsStream;
  end;



  destructor TTypedStream.Destroy;
  begin
    if FOwnsStream then
      FStream.Free;
    inherited;
  end;



  function TTypedStream.ReadAnsiString: AnsiString;
  begin
    ReadString( Result );
  end;



  procedure TTypedStream.ReadAnsiStringVar(var Result: AnsiString);
  begin
    ReadString( Result );
  end;



  function TTypedStream.ReadInteger: Integer;
  begin
    Stream.Read( Result, SizeOf(Integer) );
  end;



  procedure TTypedStream.ReadInteger(var Result: Integer);
  begin
    Stream.Read( Result, SizeOf(Integer) );
  end;



  procedure TTypedStream.ReadInteger(var Result: Int64);
  begin
    Stream.Read( Result, SizeOf(Int64) );
  end;



  function TTypedStream.ReadSmallInteger: Integer;
  var
    ByteResult: Byte;
  begin
    Stream.Read( ByteResult, SizeOf(Byte) );
    if ByteResult = cMaxSmallInt then
      Stream.Read( Result, SizeOf(Integer) )
    else
      Result := ByteResult;
  end;



  procedure TTypedStream.ReadString(var Result: AnsiString);
  var
    L: Integer;
  begin
    Stream.Read( L, SizeOf(Integer) );
    SetLength( Result, L );
    if L > 0 then
      Stream.Read( Result[1], L * SizeOf(AnsiChar) );
  end;



  procedure TTypedStream.ReadString(var Result: WideString);
  var
    L: Integer;
  begin
    Stream.Read( L, SizeOf(Integer) );
    SetLength( Result, L );
    if L > 0 then
      Stream.Read( Result[1], L * SizeOf(WideChar) );
  end;



  function TTypedStream.ReadWideString: WideString;
  begin
    ReadString( Result );
  end;



  procedure TTypedStream.ReadWideStringVar(var Result: WideString);
  begin
    ReadString( Result );
  end;



  procedure TTypedStream.SetStream(AStream: TStream);
  begin
    if FStream = AStream then Exit;
    if FOwnsStream then
      FStream.Free;
    FStream := AStream;
  end;



  procedure TTypedStream.WriteAnsiString(const Value: AnsiString);
  begin
    WriteString( Value );
  end;


  procedure TTypedStream.WriteInteger(Value: Integer);
  begin
    Stream.Write( Value, SizeOf(Integer) );
  end;



  procedure TTypedStream.WriteInteger(Value: Int64);
  begin
    Stream.Write( Value, SizeOf(Int64) );
  end;



  procedure TTypedStream.WriteSmallInteger(Value: Integer);
  var
    ByteValue: Byte;
  begin
    if (Value >= 0) and (Value < cMaxSmallInt) then
    begin
      ByteValue := Value;
      Stream.Write( ByteValue, SizeOf(Byte) )
    end
    else
    begin
      ByteValue := cMaxSmallInt;
      Stream.Write( ByteValue, SizeOf(Byte) );
      Stream.Write( Value, SizeOf(Integer) );
    end;
  end;



  procedure TTypedStream.WriteString(const Value: WideString);
  var
    L: Integer;
  begin
    L := Length(Value);
    Stream.Write( L, SizeOf(Integer) );
    if L > 0 then
      Stream.Write( Value[1], L * SizeOf(WideChar) );
  end;



  procedure TTypedStream.WriteString(const Value: AnsiString);
  var
    L: Integer;
  begin
    L := Length(Value);
    Stream.Write( L, SizeOf(Integer) );
    if L > 0 then
      Stream.Write( Value[1], L * SizeOf(AnsiChar) );
  end;



  procedure TTypedStream.WriteWideString(const Value: WideString);
  begin
    WriteString( Value );
  end;



{ TVarChar }

  procedure TVarChar.Add(const S: WideString);
  var
    I, L: Integer;
  begin
    Assert( not FOverflow );

    L := Length(S);
    if FCurCount + L > FMaxCount then
    begin
      FOverflow := True;
      Exit;
    end;
    for I := 1 to L do
      FBuffer[FCurCount + I] := S[I];
    Inc( FCurCount, L );
  end;



  constructor TVarChar.Create(AMaxCount: Integer);
  begin
    inherited Create;
    FMaxCount := AMaxCount;
    SetLength( FBuffer, FMaxCount );
    Reset;
  end;



  function TVarChar.GetIsEmpty: Boolean;
  begin
    Result := (FCurCount = 0);
  end;



  function TVarChar.GetValue: WideString;
  begin
    Result := Copy( FBuffer, 1, FCurCount );
  end;



  procedure TVarChar.Reset;
  begin
    FOverflow := False;
    FCurCount := 0;
  end;



{ TSortedList }

  procedure TSortedList.AddSorted(Obj: Pointer);
  var
    Index: Integer;
  begin
    if not Find( Obj, Index ) then
      Insert( Index, Obj );
  end;



  function TSortedList.Contains(Obj: Pointer): Boolean;
  var
    Dummy: Integer;
  begin
    Result := Find( Obj, Dummy );
  end;



  function TSortedList.Find(Obj: Pointer; var Index: Integer): Boolean;
  var
    L, H, I: Integer;
  begin
    Result := False;
    L := 0;
    H := Count - 1;
    while L <= H do
    begin
      I := (L + H) shr 1;
      if Integer(List[I]) < Integer(Obj) then
        L := I + 1
      else
      begin
        H := I - 1;
        if Integer(List[I]) = Integer(Obj) then
        begin
          Result := True;
          L := I;
        end;
      end;
    end;
    Index := L;
  end;



  procedure TSortedList.QuickSort(L, R: Integer);
  var
    I, J: Integer;
    P: Integer;
  begin
    if L = R then Exit;
    repeat
      I := L;
      J := R;
      P := Integer(List[(L + R) shr 1]);
      repeat
        while Integer(List[I]) < P do
          Inc(I);
        while Integer(List[J]) > P do
          Dec(J);
        if I <= J then
        begin
          Exchange( I, J );
          Inc( I );
          Dec( J );
        end;
      until I > J;
      if L < J then
        QuickSort(L, J);
      L := I;
    until I >= R;
  end;



  procedure TSortedList.Sort;
  begin
    if Count > 1 then
      QuickSort( 0, Count - 1);
  end;



{ TIntInterval }

  function TIntInterval.Contains(Value: Integer): Boolean;
  begin
    Result := (FLeft <= Value) and (Value <= FRight);
  end;



  constructor TIntInterval.Create(ALeft, ARight: Integer);
  begin
    inherited Create;
    Init( ALeft, ARight );
  end;



  constructor TIntInterval.Create(Value: Integer);
  begin
    inherited Create;
    Init( Value );
  end;



  constructor TIntInterval.CreateFromString(const S: WideString);
  var
    I: Integer;
    LeftStr, RightStr: WideString;
  begin
    I := WideCharPos( S, '-', 1 );
    try
      if I = 0 then
        Init( StrToInt(Trim(S)) )
      else
      begin
        LeftStr := Trim(Copy(S, 1, I-1));
        RightStr := Trim(Copy(S, I+1, MaxInt));
        if LeftStr = '' then
          Init( 0, StrToInt(RightStr) )
        else if RightStr = '' then
          Init( StrToInt(LeftStr), MaxInt )
        else
          Init( StrToInt(LeftStr), StrToInt(RightStr) );
      end
    except
      raise Exception.Create( '''' + S + ''' не является допустимой записью интервала или числа.' );
    end;
  end;



  procedure TIntInterval.Init(ALeft, ARight: Integer);
  begin
    Assert( (ALeft <= ARight) and (ALeft >= 0) );
    FLeft  := ALeft;
    FRight := ARight;
  end;



  procedure TIntInterval.Init(Value: Integer);
  begin
    Assert( Value >= 0 );
    FLeft  := Value;
    FRight := Value;
  end;



{ TIntIntervalList }

  function TIntIntervalList.Contains(Value: Integer): Boolean;
  var
    I: Integer;
  begin
    for I := 0 to FList.Count-1 do
      if TIntInterval(FList[I]).Contains(Value) then
      begin
        Result := True;
        Exit;
      end;
    Result := False;
  end;



  constructor TIntIntervalList.CreateFromString(const S: WideString);
  var
    IntList: TTntStringList;
    I: Integer;
  begin
    FList := TObjectList.Create;
    IntList := TTntStringList.Create;
    try
      CommaTextToList( S, IntList );
      for I := 0 to IntList.Count-1 do
        FList.Add( TIntInterval.CreateFromString(IntList[I]) );
    finally
      IntList.Free;
    end;
  end;



  destructor TIntIntervalList.Destroy;
  begin
    FList.Free;
    inherited;
  end;



{ TRegExprChecker }

  constructor TRegExprChecker.Create;
  begin
    FTester := TRegExpr.Create;
  end;



  destructor TRegExprChecker.Destroy;
  begin
    FTester.Free;
    inherited;
  end;



  procedure TRegExprChecker.Flush;
  begin
    FLastError := '';
    FLastPos := 0;
  end;



  function TRegExprChecker.GetErrorMsg(ErrCode: Integer): WideString;
  begin
    case ErrCode of
      reeCompParseRegTooManyBrackets:
        Result := 'Слишком много подвыражений (допустимо не больше 15)';
      reeCompParseRegUnmatchedBrackets:
        Result := 'Не хватает закрывающей круглой скобки '')''';
      reeCompParseRegUnmatchedBrackets2:
        Result := 'Лишняя закрывающая круглая скобка '')''';
      reeCompParseRegJunkOnEnd:
        Result := 'Ожидается конец выражения';
      reePlusStarOperandCouldBeEmpty:
        Result := 'Пустой операнд для ''*'', ''+''';
      reeNestedSQP:
        Result := 'Вложенные ''*'', ''?'', ''+''';
      reeBadHexDigit:
        Result := 'Неверный формат шестнадцатеричной записи числа';
      reeInvalidRange:
        Result := 'Ошибка в задании интервала [...]';
      reeParseAtomTrailingBackSlash:
        Result := '\ в конце атома';
      reeNoHexCodeAfterBSlashX:
        Result := 'Ожидается шестнадцатеричный код после ''\x''';
      reeHexCodeAfterBSlashXTooBig:
        Result := 'Длина шестнадцатеричной записи числа после ''\x'' первышает допустимую';
      reeUnmatchedSqBrackets:
        Result := 'Не хватает закрывающей квадратной скобки '']''';
      reeInternalUrp:
        Result := 'Внутренняя ошибка';
      reeQPSBFollowsNothing:
        Result := 'Отсутствует операнд для ''?'', ''+'', ''*'', ''{''';
      reeTrailingBackSlash:
        Result := '\ в конце выражения';
      reeRarseAtomInternalDisaster:
        Result := 'Внутренняя ошибка при разборе атома';
      reeBRACESArgTooBig:
        Result := 'Слишком длинная строка внутри {...}';
      reeBracesMinParamGreaterMax:
        Result := 'Нижняя граница превышает верхнюю внутри {...}';
      reeUnclosedComment:
        Result := 'Незакрытый комментарий (?#...)';
      reeComplexBracesNotImplemented:
        Result := 'Вложенные операторы {...} не реализованы';
      reeUrecognizedModifier:
        Result := 'Неизвестный модификатор';
    else
      Result := 'Неизвестная ошибка';
    end;
  end;



  function TRegExprChecker.GetExpresstion: WideString;
  begin
    Result := FTester.Expression;
  end;



  procedure TRegExprChecker.SetExpression(const Value: WideString);
  begin
    FHasError := False;
    if Value <> '' then
    begin
      FTester.Expression := Value;
      try
        FTester.Compile;
      except
        on E: ERegExpr do
        begin
          FLastError := GetErrorMsg( E.ErrorCode );
          FLastPos := E.CompilerErrorPos;
          FHasError := True;
        end
        else
        begin
          FLastError := Exception(ExceptObject).Message;
          FLastPos := 0;
          FHasError := True;
        end;
      end;
    end;
  end;



{ TDBLocker }

  procedure TDBLocker.CheckLock(ObjID: Integer);
  begin
    SetLockInfo( FCmd.QueryStoredProc( 'Locks_CanLock', VarArrayOf([FDomainID, FPropID, ObjID]) ) );
  end;



  constructor TDBLocker.Create(ACmd: TADOStoredProc; ADomainID,
    APropID: Integer);
  begin
    inherited Create;
    FCmd := ACmd;
    FDomainID := ADomainID;
    FPropID := APropID;
    FLockFree := True;
  end;



  function TDBLocker.IsLocked(ObjID: Integer): Boolean;
  begin
    CheckLock( ObjID );
    Result := not LockFree;
  end;



  procedure TDBLocker.Lock(ObjID: Integer);
  begin
    SetLockInfo( FCmd.QueryStoredProc( 'Locks_AddLock', VarArrayOf([FDomainID, FPropID, ObjID]) ) );
  end;



  procedure TDBLocker.SetLockInfo(RS: Recordset);
  begin
    FLockFree := not (Assigned(RS) and (RS.State = adStateOpen) and not RS.EOF);
    if not FLockFree then
    begin
      FLockUser := Trim(RS.Fields[0].Value);
      FLockHost := Trim(RS.Fields[1].Value);
      FLockTime := RS.Fields[2].Value;
    end;
  end;



  procedure TDBLocker.UnLock(ObjID: Integer);
  begin
    FCmd.ExecuteStoredProc( 'Locks_RemoveLock', VarArrayOf([FDomainID, FPropID, ObjID]) );
  end;



{ TMeasureStream }

  function TMeasureStream.Read(var Buffer; Count: Integer): Longint;
  begin
    Assert( False );
    Result := 0; // warning suppress
  end;



  function TMeasureStream.Write(const Buffer; Count: Integer): Longint;
  begin
    Inc( FDataSize, Count );
    Result := Count;
  end;



{ EThreadError }

  constructor EThreadError.Create(const Message: WideString);
  begin
    inherited Create( Message );
    FMessage := Message;
  end;



{ TCommonThread }

  destructor TCommonThread.Destroy;
  begin
    FError.Free;
    inherited;
  end;



  procedure TCommonThread.Execute;
  begin
    Assert( FState = cThreadState_None );
    Assert( not Assigned(FError) );

    FState := cThreadState_InWork;
    try
      try
        DoExecute;
      except
        on E: EThreadError do
          FError := EThreadError.Create( E.Message )
        else
          FError := EThreadError.Create( Exception(ExceptObject).Message );
      end;
    finally
      if Assigned(Error) then
        FState := cThreadState_Error
      else if Terminated then
        FState := cThreadState_Terminated
      else
        FState := cThreadState_Done;
    end;
  end;


  procedure TCommonThread.Terminate;
  begin
    inherited Terminate;
  end;



{ TAsyncMethodThread }

  constructor TAsyncMethodThread.Create(Method: TAsyncMethod; CreateSuspended: Boolean);
  begin
    FMethod := Method;
    inherited Create( CreateSuspended );
  end;



  procedure TAsyncMethodThread.DoExecute;
  begin
    FMethod( Self );
  end;




{ TFiledObject }

  procedure TFiledObject.AsyncLoad(Thread: TAsyncMethodThread);
  begin
    Assert( FThread = Thread );
    DoLoad;
  end;



  procedure TFiledObject.AsyncSave(Thread: TAsyncMethodThread);
  begin
    Assert( FThread = Thread );
    DoSave;
  end;



  procedure TFiledObject.CancelAsyncAction;
  begin
    if RunningAsyncAction then
      Thread.Terminate;
  end;



  procedure TFiledObject.Close;
  begin
    // all async actions must be terminated
    Assert( not RunningAsyncAction );

    DoClose;

    FFullName := '';
    FState := cFiledObjectState_Closed;
    Modified := False;
    ReadOnly := False;
  end;



  constructor TFiledObject.Create;
  begin
    inherited Create;
    // instance is created in closed state
  end;



  destructor TFiledObject.Destroy;
  begin
    // all async actions must terminate for this moment
    // ATTENTION: possible usage of Thread.WaitFor should be considered here
    Assert( not RunningAsyncAction );
    // object must be closed
    Assert( State = cFiledObjectState_Closed );
    
    inherited;
  end;



  procedure TFiledObject.DoActionDone(Action: TFiledObjectAction; State: TThreadState;
    Error: EThreadError);
  begin
    FAction := cFiledObjectAction_Idle;
    FThread := nil;

    if Modified and FPendingModified then
    begin
      ModifiedChange;
      DoModified;
    end;

    case Action of
      cFiledObjectAction_Load:
        if Assigned(Error) then
          Close
        else
          FState := cFiledObjectState_Normal;

      cFiledObjectAction_Save:
        if Assigned(Error) then
          FFullName := FOldFullName
        else
        begin
          if Modified then
            Modified := False
          else
            ModifiedChange;
        end;
    end;

    if Assigned(OnActionDone) then
      OnActionDone( Self, Action, State, Error );
  end;



  procedure TFiledObject.DoModified;
  begin
    if RunningAsyncAction then
      FPendingModified := True
    else
      if Assigned(FOnChange) then
        FOnChange( Self );  
  end;



  function TFiledObject.GetDisplayName: WideString;
  begin
    Result := FileName;
  end;


  function TFiledObject.NeedSave: Boolean;
  begin
    Result := Modified or (State = cFiledObjectState_New);
  end;


  function TFiledObject.GetFileName: WideString;
  begin
    Result := WideExtractFileName( FFullName );
  end;



  function TFiledObject.GetRunningAsyncAction: Boolean;
  begin
    Result := Assigned(FThread) or (Action <> cFiledObjectAction_Idle);
  end;



  procedure TFiledObject.InitAsyncAction(Action: TFiledObjectAction; Method: TAsyncMethod);
  var
    Thread: TAsyncMethodThread;
  begin
    Thread := TAsyncMethodThread.Create( Method, True );
    try
      InitAsyncAction( Action, Thread );
    except
      Thread.Free;
    end;
  end;



  procedure TFiledObject.InitAsyncAction(Action: TFiledObjectAction; Thread: TCommonThread);
  begin
    // all async actions must be terminated
    Assert( not RunningAsyncAction );

    FAction := Action;

    if Assigned(OnActionInit) then
      OnActionInit( Self, Action );

    FThread := Thread;
    FThread.FreeOnTerminate := True;
    FThread.OnTerminate := ThreadTerminate;

    FThread.Resume;
  end;



  procedure TFiledObject.InitSyncAction(Action: TFiledObjectAction;  Method: TSyncMethod);
  var
    Error: EThreadError;
    State: TThreadState;
  begin
    Assert( not RunningAsyncAction );

    Error := nil;
    FAction := Action;
    State := cThreadState_Done;

    if Assigned(OnActionInit) then
      OnActionInit( Self, Action );

    try
      try
        Method;
      except
        State := cThreadState_Error;
        if ExceptObject is EThreadError then
          Error := EThreadError.Create( EThreadError(ExceptObject).Message )
        else
          Error := EThreadError.Create( Exception(ExceptObject).Message );
        raise;
      end;
    finally
      try
        DoActionDone( Action, State, Error );
      finally
        Error.Free;
      end;  
    end;
  end;



  procedure TFiledObject.Load(AFileName: WideString; Async: Boolean);
  begin
    // object must be closed
    Assert( FState = cFiledObjectState_Closed );

    FFullName := AFileName;

    if not Async then
      InitSyncAction( cFiledObjectAction_Load, DoLoad )
    else
      InitAsyncAction( cFiledObjectAction_Load, AsyncLoad );
  end;



  procedure TFiledObject.ModifiedChange;
  begin
    if RunningAsyncAction then
      FPendingModified := True
    else
    begin
      if (State = cFiledObjectState_New) and not Modified then
        FState := cFiledObjectState_Normal;
      if Assigned(OnModified) then
        OnModified( Self );
    end;
  end;



  procedure TFiledObject.New;
  begin
    // object must be closed
    Assert( FState = cFiledObjectState_Closed );
    DoNew;
    FState := cFiledObjectState_New;
  end;



  procedure TFiledObject.Save(AFileName: WideString; Async: Boolean);
  begin
    // object must be opened
    Assert( State <> cFiledObjectState_Closed );

    FOldFullName := FFullName;
    FFullName := AFileName;

    if not Async then
      InitSyncAction( cFiledObjectAction_Save, DoSave )
    else
      InitAsyncAction( cFiledObjectAction_Save, AsyncSave );
  end;



  procedure TFiledObject.SetModified(const Value: Boolean);
  begin
    if Modified <> Value then
    begin
      FModified := Value;
      ModifiedChange;
    end;
    if Modified then
      DoModified;
  end;



  procedure TFiledObject.SetPosition(const Value: Integer);
  var
    TmpStep: Integer;
  begin
    FPosition := Value;
    TmpStep := (Position * 100) div Total;
    if TmpStep <> Step then
      Step := TmpStep;
  end;



  procedure TFiledObject.SetReadOnly(const Value: Boolean);
  begin
    Assert( not RunningAsyncAction and not Assigned(FThread) );
    FReadOnly := Value;
  end;



  procedure TFiledObject.SetStep(const Value: Integer);
  begin
    FStep := Value;
    if RunningAsyncAction and Assigned(OnActionStep) then
      Thread.Synchronize( SyncDoStep );
  end;



  procedure TFiledObject.SetTotal(const Value: Integer);
  begin
    FTotal := Value;
    FStep := 0;
    FPosition := 0;
  end;



  procedure TFiledObject.SyncDoStep;
  begin
    if Assigned(OnActionStep) then
      OnActionStep( Self, Action, Step );
  end;



  procedure TFiledObject.ThreadTerminate(Sender: TObject);
  var
    State: TThreadState;
    Error: EThreadError;
  begin
    State := TCommonThread(Sender).State;
    Error := TCommonThread(Sender).Error;
    DoActionDone( Action, State, Error );
  end;

//======================================================================================================================
// EBaseError
//----------------------------------------------------------------------------------------------------------------------

  constructor EBaseError.Create(const Error: string;
    const Source: WideString; Position: Integer; Category: string);

  begin
    FError := Error;
    FSource := Source;
    FPosition := Position;
    if Category = '' then
      FCategory := 'Error'
    else
      FCategory := Category;

    UpdateMessage;
  end;

//----------------------------------------------------------------------------------------------------------------------

  procedure EBaseError.UpdateMessage;

  var
    FromI, ToI: Integer;
    Left, Context: WideString;

  begin
    if FSource = '' then
      Context := ''
    else
    begin
      FromI := FPosition;
      ToI := FPosition;
      while (FromI > 0) and (FSource[FromI] <> #10) and (FSource[FromI] <> #13) do
        Dec(FromI);
      Inc (FromI);
      while (FSource[ToI] <> #10) and (FSource[ToI] <> #13) and (FSource[ToI] <> #0) do
        Inc(ToI);
      Dec(ToI);
      Left := Copy(FSource, FromI, FPosition - FromI);
      if Left <> '' then
        Left := WideQuotedStr(Left) + ' ';
      Context := Left + '--> ' + WideQuotedStr(Copy(FSource, FPosition, ToI - FPosition + 1));
    end;

    FMessage := UpperCase(Category) + ':  ' + FError;

    if Context <> '' then
      FMessage := FMessage + #13#10'CONTEXT:  ' + Context;
    inherited Message := FMessage;
  end;

//----------------------------------------------------------------------------------------------------------------------

  function CheckToIs(CheckMethod: TCheckMethod): Boolean;

  begin
    try
      CheckMethod;
      Result := True;
    except
      Result := False;
    end;
  end;

//----------------------------------------------------------------------------------------------------------------------

  function CheckToIsWithMessage(CheckMethod: TCheckMethod): Boolean;

  begin
    try
      CheckMethod;
      Result := True;
    except
      ShowGeneralError(Exception(ExceptObject).Message);
      Result := False;
    end;
  end;

end.

