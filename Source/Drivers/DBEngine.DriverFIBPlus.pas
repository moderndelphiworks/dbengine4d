{
  DBE Brasil � um Engine de Conex�o simples e descomplicado for Delphi/Lazarus

                   Copyright (c) 2016, Isaque Pinheiro
                          All rights reserved.

                    GNU Lesser General Public License
                      Vers�o 3, 29 de junho de 2007

       Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
       A todos � permitido copiar e distribuir c�pias deste documento de
       licen�a, mas mud�-lo n�o � permitido.

       Esta vers�o da GNU Lesser General Public License incorpora
       os termos e condi��es da vers�o 3 da GNU General Public License
       Licen�a, complementado pelas permiss�es adicionais listadas no
       arquivo LICENSE na pasta principal.
}

{ @abstract(DBE Framework)
  @created(20 Jul 2016)
  @author(Isaque Pinheiro <https://www.isaquepinheiro.com.br>)
}

unit DBEngine.DriverFIBPlus;

interface

uses
  Classes,
  DB,
  Variants,
  SysUtils,

  FIBQuery,
  FIBDataSet,
  FIBDatabase,

  // DBE
  DBE.DriverConnection,
  DBE.FactoryInterfaces;

type
  // Classe de conex�o concreta com dbExpress
  TDriverFIBPlus = class(TDriverConnection)
  protected
    FConnection: TFIBDatabase;
    FSQLScript: TFIBQuery;
  public
    constructor Create(const AConnection: TComponent;
      const ADriverName: TDriverName); override;
    destructor Destroy; override;
    procedure Connect; override;
    procedure Disconnect; override;
    procedure ExecuteDirect(const ASQL: String); overload; override;
    procedure ExecuteDirect(const ASQL: String;
      const AParams: TParams); overload; override;
    procedure ExecuteScript(const AScript: String); override;
    procedure AddScript(const AScript: String); override;
    procedure ExecuteScripts; override;
    function IsConnected: Boolean; override;
    function InTransaction: Boolean; override;
    function CreateQuery: IDBQuery; override;
    function CreateDataSet(const ASQL: String): IDBResultSet; override;
  end;

  TDriverQueryFIBPlus = class(TDriverQuery)
  private
    FSQLQuery: TFIBQuery;
  protected
    procedure SetCommandText(ACommandText: String); override;
    function GetCommandText: String; override;
  public
    constructor Create(AConnection: TFIBDatabase);
    destructor Destroy; override;
    procedure ExecuteDirect; override;
    function ExecuteQuery: IDBResultSet; override;
  end;

  TDriverResultSetFIBPlus = class(TDriverResultSetBase)
  protected
    FDataSet: TFIBDataSet;
  public
    constructor Create(ADataSet: TFIBDataSet); overload;
    destructor Destroy; override;
    procedure Close; override;
    function NotEof: Boolean; override;
    function GetFieldValue(const AFieldName: String): Variant; overload; override;
    function GetFieldValue(const AFieldIndex: UInt16): Variant; overload; override;
    function GetFieldType(const AFieldName: String): TFieldType; overload; override;
    function GetField(const AFieldName: String): TField; override;
    function FieldDefs: TFieldDefs; override;
    function DataSet: TDataSet; override;
  end;

implementation

{ TDriverFIBPlus }

constructor TDriverFIBPlus.Create(const AConnection: TComponent;
  const ADriverName: TDriverName);
begin
  inherited;
  FConnection := AConnection as TFIBDatabase;
  FDriverName := ADriverName;
  FSQLScript := TFIBQuery.Create(nil);
  try
    FSQLScript.Database := FConnection;
    FSQLScript.Transaction := FConnection.DefaultTransaction;
  except
    on E: Exception do
    begin
      FSQLScript.Free;
      raise Exception.Create(E.Message);
    end;
  end;
end;

destructor TDriverFIBPlus.Destroy;
begin
  FConnection := nil;
  FSQLScript.Free;
  inherited;
end;

procedure TDriverFIBPlus.Disconnect;
begin
  inherited;
  FConnection.Connected := False;
end;

procedure TDriverFIBPlus.ExecuteDirect(const ASQL: String);
begin
  inherited;
  ExecuteDirect(ASQL, nil);
end;

procedure TDriverFIBPlus.ExecuteDirect(const ASQL: String; const AParams: TParams);
var
  LExeSQL: TFIBQuery;
  LFor: Int16;
begin
  inherited;
  LExeSQL := TFIBQuery.Create(nil);
  try
    LExeSQL.Database := FConnection;
    LExeSQL.Transaction := FConnection.DefaultTransaction;
    LExeSQL.SQL.Text := ASQL;
    if AParams <> nil then
    begin
      for LFor := 0 to AParams.Count - 1 do
      begin
//        LExeSQL.Params.ParamByName(AParams[LFor].Name).ElementType := AParams[LFor].DataType;
        LExeSQL.Params.ParamByName(AParams[LFor].Name).Value       := AParams[LFor].Value;
      end;
    end;
    LExeSQL.ExecQuery;
  finally
    LExeSQL.Free;
  end;
end;

procedure TDriverFIBPlus.ExecuteScript(const AScript: String);
begin
  inherited;
  FSQLScript.SQL.Text := AScript;
  FSQLScript.ExecQuery;
end;

procedure TDriverFIBPlus.ExecuteScripts;
begin
  inherited;
  try
    FSQLScript.ExecQuery;
  finally
    FSQLScript.SQL.Clear;
  end;
end;

procedure TDriverFIBPlus.AddScript(const AScript: String);
begin
  inherited;
  FSQLScript.SQL.Add(AScript);
end;

procedure TDriverFIBPlus.Connect;
begin
  inherited;
  FConnection.Connected := True;
end;

function TDriverFIBPlus.InTransaction: Boolean;
begin
  inherited;
  Result := FConnection.DefaultTransaction.InTransaction;
end;

function TDriverFIBPlus.IsConnected: Boolean;
begin
  inherited;
  Result := FConnection.Connected;
end;

function TDriverFIBPlus.CreateQuery: IDBQuery;
begin
  inherited;
  Result := TDriverQueryFIBPlus.Create(FConnection);
end;

function TDriverFIBPlus.CreateDataSet(const ASQL: String): IDBResultSet;
var
  LDBQuery: IDBQuery;
begin
  inherited;
  LDBQuery := TDriverQueryFIBPlus.Create(FConnection);
  LDBQuery.CommandText := ASQL;
  Result   := LDBQuery.ExecuteQuery;
end;

{ TDriverDBExpressQuery }

constructor TDriverQueryFIBPlus.Create(AConnection: TFIBDatabase);
begin
  if AConnection = nil then
    Exit;

  FSQLQuery := TFIBQuery.Create(nil);
  try
    FSQLQuery.Database := AConnection;
    FSQLQuery.Transaction := AConnection.DefaultTransaction;
  except
    on E: Exception do
    begin
      FSQLQuery.Free;
      raise Exception.Create(E.Message);
    end;
  end;
end;

destructor TDriverQueryFIBPlus.Destroy;
begin
  FSQLQuery.Free;
  inherited;
end;

function TDriverQueryFIBPlus.ExecuteQuery: IDBResultSet;
var
  LResultSet: TFIBDataSet;
  LFor: Int16;
begin
  inherited;
  LResultSet := TFIBDataSet.Create(nil);
  try
    LResultSet.Database := FSQLQuery.Database;
    LResultSet.Transaction := FSQLQuery.Transaction;
    LResultSet.SelectSQL.Text := FSQLQuery.SQL.Text;

    for LFor := 0 to FSQLQuery.Params.Count - 1 do
    begin
//      LResultSet.Params[LFor].ElementType := FSQLQuery.Params[LFor].ElementType;
      LResultSet.Params[LFor].Value       := FSQLQuery.Params[LFor].Value;
    end;
    if not LResultSet.Database.Connected then
      LResultSet.Database.Open;

    if not LResultSet.Transaction.InTransaction then
      LResultSet.Transaction.StartTransaction;
    LResultSet.Open;
  except
    on E: Exception do
    begin
      LResultSet.Free;
      raise Exception.Create(E.Message);
    end;
  end;
  Result := TDriverResultSetFIBPlus.Create(LResultSet);
  if LResultSet.RecordCount = 0 then
     Result.FetchingAll := True;
end;

function TDriverQueryFIBPlus.GetCommandText: String;
begin
  Result := FSQLQuery.SQL.Text;
end;

procedure TDriverQueryFIBPlus.SetCommandText(ACommandText: String);
begin
  inherited;
  FSQLQuery.SQL.Text := ACommandText;
end;

procedure TDriverQueryFIBPlus.ExecuteDirect;
begin
  inherited;
  if not FSQLQuery.Database.Connected then
    FSQLQuery.Database.Open;

  if not FSQLQuery.Transaction.InTransaction then
    FSQLQuery.Transaction.StartTransaction;
  try
    FSQLQuery.ExecQuery;
    FSQLQuery.Transaction.Commit;
  except
    FSQLQuery.Transaction.Rollback;
  end;
end;

{ TDriverResultSetFIBPlus }

procedure TDriverResultSetFIBPlus.Close;
begin
  inherited;
  FDataSet.Close;
end;

constructor TDriverResultSetFIBPlus.Create(ADataSet: TFIBDataSet);
begin
  Create;
  FDataSet := ADataSet;
  FRecordCount := FDataSet.RecordCount;
end;

function TDriverResultSetFIBPlus.DataSet: TDataSet;
begin
  Result := FDataSet;
end;

destructor TDriverResultSetFIBPlus.Destroy;
begin
  FDataSet.Free;
  inherited;
end;

function TDriverResultSetFIBPlus.FieldDefs: TFieldDefs;
begin
  inherited;
  Result := FDataSet.FieldDefs;
end;

function TDriverResultSetFIBPlus.GetFieldValue(const AFieldName: String): Variant;
begin
  inherited;
  Result := FDataSet.FieldByName(AFieldName).Value;
end;

function TDriverResultSetFIBPlus.GetField(const AFieldName: String): TField;
begin
  inherited;
  Result := FDataSet.FieldByName(AFieldName);
end;

function TDriverResultSetFIBPlus.GetFieldType(const AFieldName: String): TFieldType;
begin
  inherited;
  Result := FDataSet.FieldByName(AFieldName).DataType;
end;

function TDriverResultSetFIBPlus.GetFieldValue(const AFieldIndex: UINt16): Variant;
begin
  inherited;
  if AFieldIndex > FDataSet.FieldCount -1  then
    Exit(Variants.Null);

  if FDataSet.Fields[AFieldIndex].IsNull then
    Result := Variants.Null
  else
    Result := FDataSet.Fields[AFieldIndex].Value;
end;

function TDriverResultSetFIBPlus.NotEof: Boolean;
begin
  inherited;
  if not FFirstNext then
    FFirstNext := True
  else
     FDataSet.Next;

  Result := not FDataSet.Eof;
end;

end.