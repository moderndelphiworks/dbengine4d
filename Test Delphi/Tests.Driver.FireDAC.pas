unit Tests.Driver.FireDAC;

interface
uses
  DUnitX.TestFramework,

  System.SysUtils,
  Data.DB,

  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Stan.Intf,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.VCLUI.Wait,
  FireDAC.Stan.ExprFuncs,
  FireDAC.Comp.UI,
  FireDAC.DApt,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet,

  DBEngine.FactoryInterfaces;

type
  [TestFixture]
  TTestDriverConnection = class(TObject)
  strict private
    FConnection: TFDConnection;
    FDBConnection: IDBConnection;
    FDBQuery: IDBQuery;
    FDBResultSet: IDBDataSet;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestConnect;
    [Test]
    procedure TestDisconnect;
    [Test]
    procedure TestExecuteDirect;
    [Test]
    procedure TestExecuteDirectParams;
    [Test]
    procedure TestExecuteScript;
    [Test]
    procedure TestAddScript;
    [Test]
    procedure TestExecuteScripts;
    [Test]
    procedure TestIsConnected;
    [Test]
    procedure TestInTransaction;
    [Test]
    procedure TestCreateQuery;
    [Test]
    procedure TestCreateDataSet;
    [Test]
    procedure TestStartTransaction;
    [Test]
    procedure TestCommit;
    [Test]
    procedure TestRollback;
  end;

implementation

uses
  DBEngine.FactoryFireDac,
  Tests.Consts;

{ TTestDriverConnection }

procedure TTestDriverConnection.Setup;
begin
  FConnection := TFDConnection.Create(nil);
  FConnection.Params.DriverID := 'SQLite';
  FConnection.Params.Database := '.\database.db3';
  FConnection.LoginPrompt := False;
  FConnection.TxOptions.Isolation := xiReadCommitted;
  FConnection.TxOptions.AutoCommit := False;

  FDBConnection := TFactoryFireDAC.Create(FConnection, dnSQLite);
end;

procedure TTestDriverConnection.TestCommit;
begin
  TestStartTransaction;

  FDBConnection.Commit;
  Assert.IsFalse(FDBConnection.InTransaction, 'FConnection.InTransaction = False');
end;

procedure TTestDriverConnection.TestExecuteDirect;
var
  LValue: String;
  LRandon: String;
begin
  LRandon := IntToStr( Random(9999) );

  FDBConnection.ExecuteDirect( Format(cSQLUPDATE, [QuotedStr(cDESCRIPTION + LRandon), '1']) );

  FDBQuery := FDBConnection.CreateQuery;
  FDBQuery.CommandText := Format(cSQLSELECT, ['1']);
  LValue := FDBQuery.ExecuteQuery.FieldByName('CLIENT_NAME').AsString;

  Assert.AreEqual(LValue, cDESCRIPTION + LRandon, LValue + ' <> ' + cDESCRIPTION + LRandon);
end;

procedure TTestDriverConnection.TestExecuteDirectParams;
var
  LParams: TParams;
  LRandon: String;
  LValue: String;
begin
  LRandon := IntToStr( Random(9999) );

  LParams := TParams.Create(nil);
  try
    with LParams.Add as TParam do
    begin
      Name := 'CLIENT_NAME';
      DataType := ftString;
      Value := cDESCRIPTION + LRandon;
      ParamType := ptInput;
    end;
    with LParams.Add as TParam do
    begin
      Name := 'CLIENT_ID';
      DataType := ftInteger;
      Value := 1;
      ParamType := ptInput;
    end;
    FDBConnection.ExecuteDirect(cSQLUPDATEPARAM, LParams);

    FDBResultSet := FDBConnection.CreateDataSet(Format(cSQLSELECT, ['1']));
    LValue := FDBResultSet.FieldByName('CLIENT_NAME').AsString;

    Assert.AreEqual(LValue, cDESCRIPTION + LRandon, LValue + ' <> ' + cDESCRIPTION + LRandon);
  finally
    LParams.Free;
  end;
end;

procedure TTestDriverConnection.TestExecuteScript;
begin
  Assert.Pass('');
end;

procedure TTestDriverConnection.TestExecuteScripts;
begin
  Assert.Pass('');
end;

procedure TTestDriverConnection.TestInTransaction;
begin
  FDBConnection.Connect;
  FDBConnection.StartTransaction;

  Assert.AreEqual(FDBConnection.InTransaction, FConnection.InTransaction, 'FConnection.InTransaction <> FFDConnection.InTransaction');

  FDBConnection.Rollback;
  FDBConnection.Disconnect;
end;

procedure TTestDriverConnection.TestIsConnected;
begin
  Assert.IsFalse(FDBConnection.IsConnected, 'FConnection.IsConnected = False');
end;

procedure TTestDriverConnection.TestRollback;
begin
  TestStartTransaction;

  FDBConnection.Rollback;
  Assert.IsFalse(FDBConnection.InTransaction, 'FConnection.InTransaction = False');
end;

procedure TTestDriverConnection.TestStartTransaction;
begin
  FDBConnection.StartTransaction;
  Assert.IsTrue(FDBConnection.InTransaction, 'FConnection.InTransaction = True');
end;

procedure TTestDriverConnection.TearDown;
begin
  if Assigned(FConnection) then
    FConnection.Free;
end;

procedure TTestDriverConnection.TestAddScript;
begin
  Assert.Pass('');
end;

procedure TTestDriverConnection.TestConnect;
begin
  FDBConnection.Connect;
  Assert.IsTrue(FDBConnection.IsConnected, 'FConnection.IsConnected = True');
end;

procedure TTestDriverConnection.TestCreateQuery;
var
  LValue: String;
  LRandon: String;
begin
  LRandon := IntToStr( Random(9999) );

  FDBQuery := FDBConnection.CreateQuery;
  FDBQuery.CommandText := Format(cSQLUPDATE, [QuotedStr(cDESCRIPTION + LRandon), '1']);
  FDBQuery.ExecuteDirect;

  FDBQuery.CommandText := Format(cSQLSELECT, ['1']);
  LValue := FDBQuery.ExecuteQuery.FieldByName('CLIENT_NAME').AsString;

  Assert.AreEqual(LValue, cDESCRIPTION + LRandon, LValue + ' <> ' + cDESCRIPTION + LRandon);
end;

procedure TTestDriverConnection.TestCreateDataSet;
begin
  FDBResultSet := FDBConnection.CreateDataSet(Format(cSQLSELECT, ['1']));

  Assert.IsTrue(FDBResultSet.RecordCount = 1, 'FDBResultSet.RecordCount = ' + IntToStr(FDBResultSet.RecordCount));
end;

procedure TTestDriverConnection.TestDisconnect;
begin
  FDBConnection.Disconnect;
  Assert.IsFalse(FDBConnection.IsConnected, 'FConnection.IsConnected = False');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDriverConnection);
end.


