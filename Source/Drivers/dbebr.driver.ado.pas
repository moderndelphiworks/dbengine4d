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

{ @abstract(DBEBr Framework)
  @created(20 Jul 2016)
  @author(Isaque Pinheiro <https://www.isaquepinheiro.com.br>)
}

unit dbebr.driver.ado;

interface

uses
  Classes,
  SysUtils,
  DB,
  Variants,
  ADODB,
  /// DBEBr
  dbebr.driver.connection,
  dbebr.factory.interfaces;

type
  // Classe de conex�o concreta com dbExpress
  TDriverADO = class(TDriverConnection)
  protected
    FConnection: TADOConnection;
    FSQLScript: TADOQuery;
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
    function CreateResultSet(const ASQL: String): IDBResultSet; override;
  end;

  TDriverQueryADO = class(TDriverQuery)
  private
    FSQLQuery: TADOQuery;
  protected
    procedure SetCommandText(ACommandText: String); override;
    function GetCommandText: String; override;
  public
    constructor Create(AConnection: TADOConnection);
    destructor Destroy; override;
    procedure ExecuteDirect; override;
    function ExecuteQuery: IDBResultSet; override;
  end;

  TDriverResultSetADO = class(TDriverResultSet<TADOQuery>)
  public
    constructor Create(ADataSet: TADOQuery); override;
    destructor Destroy; override;
    function NotEof: Boolean; override;
    function GetFieldValue(const AFieldName: String): Variant; overload; override;
    function GetFieldValue(const AFieldIndex: UInt16): Variant; overload; override;
    function GetFieldType(const AFieldName: String): TFieldType; overload; override;
    function GetField(const AFieldName: String): TField; override;
  end;

implementation

{ TDriverADO }

constructor TDriverADO.Create(const AConnection: TComponent;
  const ADriverName: TDriverName);
begin
  inherited;
  FConnection := AConnection as TADOConnection;
  FDriverName := ADriverName;
  FSQLScript := TADOQuery.Create(nil);
  try
    FSQLScript.Connection := FConnection;
  except
    FSQLScript.Free;
    raise;
  end;
end;

destructor TDriverADO.Destroy;
begin
  FConnection := nil;
  FSQLScript.Free;
  inherited;
end;

procedure TDriverADO.Disconnect;
begin
  inherited;
  FConnection.Connected := False;
end;

procedure TDriverADO.ExecuteDirect(const ASQL: String);
begin
  inherited;
  FConnection.Execute(ASQL);
end;

procedure TDriverADO.ExecuteDirect(const ASQL: String; const AParams: TParams);
var
  LExeSQL: TADOQuery;
  LFor: Int16;
begin
  LExeSQL := TADOQuery.Create(nil);
  try
    LExeSQL.Connection := FConnection;
    LExeSQL.SQL.Text   := ASQL;
    for LFor := 0 to AParams.Count - 1 do
    begin
      LExeSQL.Parameters.ParamByName(AParams[LFor].Name).DataType := AParams[LFor].DataType;
      LExeSQL.Parameters.ParamByName(AParams[LFor].Name).Value    := AParams[LFor].Value;
    end;
    try
      LExeSQL.ExecSQL;
    except
      raise;
    end;
  finally
    LExeSQL.Free;
  end;
end;

procedure TDriverADO.ExecuteScript(const AScript: String);
begin
  inherited;
  FSQLScript.SQL.Text := AScript;
  FSQLScript.ExecSQL;
end;

procedure TDriverADO.ExecuteScripts;
begin
  inherited;
  try
    FSQLScript.ExecSQL;
  finally
    FSQLScript.SQL.Clear;
  end;
end;

procedure TDriverADO.AddScript(const AScript: String);
begin
  inherited;
  FSQLScript.SQL.Add(AScript);
end;

procedure TDriverADO.Connect;
begin
  inherited;
  FConnection.Connected := True;
end;

function TDriverADO.InTransaction: Boolean;
begin
  inherited;
  Result := FConnection.InTransaction;
end;

function TDriverADO.IsConnected: Boolean;
begin
  inherited;
  Result := FConnection.Connected = True;
end;

function TDriverADO.CreateQuery: IDBQuery;
begin
  Result := TDriverQueryADO.Create(FConnection);
end;

function TDriverADO.CreateResultSet(const ASQL: String): IDBResultSet;
var
  LDBQuery: IDBQuery;
begin
  LDBQuery := TDriverQueryADO.Create(FConnection);
  LDBQuery.CommandText := ASQL;
  Result   := LDBQuery.ExecuteQuery;
end;

{ TDriverDBExpressQuery }

constructor TDriverQueryADO.Create(AConnection: TADOConnection);
begin
  if AConnection = nil then
    Exit;
  FSQLQuery := TADOQuery.Create(nil);
  try
    FSQLQuery.Connection := AConnection;
  except
    FSQLQuery.Free;
    raise;
  end;
end;

destructor TDriverQueryADO.Destroy;
begin
  FSQLQuery.Free;
  inherited;
end;

function TDriverQueryADO.ExecuteQuery: IDBResultSet;
var
  LResultSet: TADOQuery;
  LFor: Int16;
begin
  LResultSet := TADOQuery.Create(nil);
  try
    LResultSet.Connection := FSQLQuery.Connection;
    LResultSet.SQL.Text := FSQLQuery.SQL.Text;

    for LFor := 0 to FSQLQuery.Parameters.Count - 1 do
    begin
      LResultSet.Parameters[LFor].DataType := FSQLQuery.Parameters[LFor].DataType;
      LResultSet.Parameters[LFor].Value    := FSQLQuery.Parameters[LFor].Value;
    end;
    LResultSet.Open;
  except
    LResultSet.Free;
    raise;
  end;
  Result := TDriverResultSetADO.Create(LResultSet);
  if LResultSet.RecordCount = 0 then
     Result.FetchingAll := True;
end;

function TDriverQueryADO.GetCommandText: String;
begin
  Result := FSQLQuery.SQL.Text;
end;

procedure TDriverQueryADO.SetCommandText(ACommandText: String);
begin
  inherited;
  FSQLQuery.SQL.Text := ACommandText;
end;

procedure TDriverQueryADO.ExecuteDirect;
begin
  FSQLQuery.ExecSQL;
end;

{ TDriverResultSetADO }

constructor TDriverResultSetADO.Create(ADataSet: TADOQuery);
begin
  FDataSet:= ADataSet;
  inherited;
end;

destructor TDriverResultSetADO.Destroy;
begin
  FDataSet.Free;
  inherited;
end;

function TDriverResultSetADO.GetFieldValue(const AFieldName: String): Variant;
var
  LField: TField;
begin
  LField := FDataSet.FieldByName(AFieldName);
  Result := GetFieldValue(LField.Index);
end;

function TDriverResultSetADO.GetField(const AFieldName: String): TField;
begin
  Result := FDataSet.FieldByName(AFieldName);
end;

function TDriverResultSetADO.GetFieldType(const AFieldName: String): TFieldType;
begin
  Result := FDataSet.FieldByName(AFieldName).DataType;
end;

function TDriverResultSetADO.GetFieldValue(const AFieldIndex: UInt16): Variant;
begin
  if AFieldIndex > FDataSet.FieldCount -1  then
    Exit(Variants.Null);

  if FDataSet.Fields[AFieldIndex].IsNull then
     Result := Variants.Null
  else
     Result := FDataSet.Fields[AFieldIndex].Value;
end;

function TDriverResultSetADO.NotEof: Boolean;
begin
  if not FFirstNext then
     FFirstNext := True
  else
     FDataSet.Next;

  Result := not FDataSet.Eof;
end;

end.
