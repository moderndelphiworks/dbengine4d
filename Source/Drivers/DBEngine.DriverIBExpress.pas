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

unit DBEngine.DriverIBExpress;

interface

uses
  Classes,
  DB,
  Variants,
  SysUtils,

  IBScript,
  IBCustomDataSet,
  IBQuery,
  IBDatabase,

  // DBE
  DBE.DriverConnection,
  DBE.FactoryInterfaces;

type
  // Classe de conex�o concreta com dbExpress
  TDriverIBExpress = class(TDriverConnection)
  protected
    FConnection: TIBDatabase;
    FSQLScript: TIBScript;
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

  TDriverQueryIBExpress = class(TDriverQuery)
  private
    FSQLQuery: TIBQuery;
  protected
    procedure SetCommandText(ACommandText: String); override;
    function GetCommandText: String; override;
  public
    constructor Create(AConnection: TIBDatabase);
    destructor Destroy; override;
    procedure ExecuteDirect; override;
    function ExecuteQuery: IDBResultSet; override;
  end;

  TDriverResultSetIBExpress = class(TDriverResultSet<TIBQuery>)
  public
    constructor Create(ADataSet: TIBQuery); override;
    destructor Destroy; override;
    function NotEof: Boolean; override;
    function GetFieldValue(const AFieldName: String): Variant; overload; override;
    function GetFieldValue(const AFieldIndex: UInt16): Variant; overload; override;
    function GetFieldType(const AFieldName: String): TFieldType; overload; override;
    function GetField(const AFieldName: String): TField; override;
  end;

implementation

{ TDriverIBExpress }

constructor TDriverIBExpress.Create(const AConnection: TComponent;
  const ADriverName: TDriverName);
begin
  inherited;
  FConnection := AConnection as TIBDatabase;
  FDriverName := ADriverName;
  FSQLScript := TIBScript.Create(nil);
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

destructor TDriverIBExpress.Destroy;
begin
  FConnection := nil;
  FSQLScript.Free;
  inherited;
end;

procedure TDriverIBExpress.Disconnect;
begin
  inherited;
  FConnection.Connected := False;
end;

procedure TDriverIBExpress.ExecuteDirect(const ASQL: String);
begin
  inherited;
  ExecuteDirect(ASQL, nil);
end;

procedure TDriverIBExpress.ExecuteDirect(const ASQL: String; const AParams: TParams);
var
  LExeSQL: TIBQuery;
  LFor: UInt16;
begin
  inherited;
  LExeSQL := TIBQuery.Create(nil);
  try
    LExeSQL.Database := FConnection;
    LExeSQL.Transaction := FConnection.DefaultTransaction;
    LExeSQL.SQL.Text := ASQL;
    if AParams <> nil then
    begin
      for LFor := 0 to AParams.Count - 1 do
      begin
        LExeSQL.ParamByName(AParams[LFor].Name).DataType := AParams[LFor].DataType;
        LExeSQL.ParamByName(AParams[LFor].Name).Value    := AParams[LFor].Value;
      end;
    end;
    LExeSQL.ExecSQL;
  finally
    LExeSQL.Free;
  end;
end;

procedure TDriverIBExpress.ExecuteScript(const AScript: String);
begin
  inherited;
  FSQLScript.Script.Text := AScript;
  FSQLScript.ExecuteScript;
end;

procedure TDriverIBExpress.ExecuteScripts;
begin
  inherited;
  try
    FSQLScript.ExecuteScript;
  finally
    FSQLScript.Script.Clear;
  end;
end;

procedure TDriverIBExpress.AddScript(const AScript: String);
begin
  inherited;
  FSQLScript.Script.Add(AScript);
end;

procedure TDriverIBExpress.Connect;
begin
  inherited;
  FConnection.Connected := True;
end;

function TDriverIBExpress.InTransaction: Boolean;
begin
  inherited;
  Result := FConnection.DefaultTransaction.InTransaction;
end;

function TDriverIBExpress.IsConnected: Boolean;
begin
  inherited;
  Result := FConnection.Connected;
end;

function TDriverIBExpress.CreateQuery: IDBQuery;
begin
  Result := TDriverQueryIBExpress.Create(FConnection);
end;

function TDriverIBExpress.CreateDataSet(const ASQL: String): IDBResultSet;
var
  LDBQuery: IDBQuery;
begin
  LDBQuery := TDriverQueryIBExpress.Create(FConnection);
  LDBQuery.CommandText := ASQL;
  Result   := LDBQuery.ExecuteQuery;
end;

{ TDriverDBExpressQuery }

constructor TDriverQueryIBExpress.Create(AConnection: TIBDatabase);
begin
  if AConnection = nil then
    Exit;

  FSQLQuery := TIBQuery.Create(nil);
  try
    FSQLQuery.Database := AConnection;
    FSQLQuery.Transaction := AConnection.DefaultTransaction;
    FSQLQuery.UniDirectional := True;
  except
    on E: Exception do
    begin
      FSQLQuery.Free;
      raise Exception.Create(E.Message);
    end;
  end;
end;

destructor TDriverQueryIBExpress.Destroy;
begin
  FSQLQuery.Free;
  inherited;
end;

function TDriverQueryIBExpress.ExecuteQuery: IDBResultSet;
var
  LResultSet: TIBQuery;
  LFor: UInt16;
begin
  LResultSet := TIBQuery.Create(nil);
  try
    LResultSet.Database := FSQLQuery.Database;
    LResultSet.Transaction := FSQLQuery.Transaction;
    LResultSet.UniDirectional := True;
    LResultSet.SQL.Text := FSQLQuery.SQL.Text;

    for LFor := 0 to FSQLQuery.Params.Count - 1 do
    begin
      LResultSet.Params[LFor].DataType := FSQLQuery.Params[LFor].DataType;
      LResultSet.Params[LFor].Value    := FSQLQuery.Params[LFor].Value;
    end;
    LResultSet.Open;
  except
    on E: Exception do
    begin
      LResultSet.Free;
      raise Exception.Create(E.Message);
    end;
  end;
  Result := TDriverResultSetIBExpress.Create(LResultSet);
  if LResultSet.RecordCount = 0 then
     Result.FetchingAll := True;
end;

function TDriverQueryIBExpress.GetCommandText: String;
begin
  Result := FSQLQuery.SQL.Text;
end;

procedure TDriverQueryIBExpress.SetCommandText(ACommandText: String);
begin
  inherited;
  FSQLQuery.SQL.Text := ACommandText;
end;

procedure TDriverQueryIBExpress.ExecuteDirect;
begin
  FSQLQuery.ExecSQL;
end;

{ TDriverResultSetIBExpress }

constructor TDriverResultSetIBExpress.Create(ADataSet: TIBQuery);
begin
  FDataSet := ADataSet;
  inherited;
end;

destructor TDriverResultSetIBExpress.Destroy;
begin
  FDataSet.Free;
  inherited;
end;

function TDriverResultSetIBExpress.GetFieldValue(const AFieldName: String): Variant;
var
  LField: TField;
begin
  LField := FDataSet.FieldByName(AFieldName);
  Result := GetFieldValue(LField.Index);
end;

function TDriverResultSetIBExpress.GetField(const AFieldName: String): TField;
begin
  inherited;
  Result := FDataSet.FieldByName(AFieldName);
end;

function TDriverResultSetIBExpress.GetFieldType(const AFieldName: String): TFieldType;
begin
  Result := FDataSet.FieldByName(AFieldName).DataType;
end;

function TDriverResultSetIBExpress.GetFieldValue(const AFieldIndex: Integer): Variant;
begin
  if AFieldIndex > FDataSet.FieldCount -1  then
    Exit(Variants.Null);

  if FDataSet.Fields[AFieldIndex].IsNull then
    Result := Variants.Null
  else
    Result := FDataSet.Fields[AFieldIndex].Value;
end;

function TDriverResultSetIBExpress.NotEof: Boolean;
begin
  if not FFirstNext then
     FFirstNext := True
  else
     FDataSet.Next;
  Result := not FDataSet.Eof;
end;

end.