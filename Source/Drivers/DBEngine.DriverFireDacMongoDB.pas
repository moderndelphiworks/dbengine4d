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

unit DBEngine.DriverFireDacMongoDB;

interface

uses
  Classes,
  SysUtils,
  StrUtils,
  JSON.Types,
  JSON.Readers,
  JSON.BSON,
  JSON.Builders,
  Variants,
  Data.DB,
  // FireDAC
  FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.MongoDB,
  FireDAC.Phys.MongoDBDef, FireDAC.Phys.MongoDBWrapper,
  FireDAC.VCLUI.Wait, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.Phys.MongoDBDataSet, FireDAC.Comp.Client,
  FireDAC.Comp.UI,
  // DBE
  DBE.DriverConnection,
  DBE.FactoryInterfaces;

type
  // Classe de conex�o concreta com FireDAC
  TDriverMongoFireDAC = class(TDriverConnection)
  protected
    FConnection: TFDConnection;
//    FSQLScript : TFDMongoQuery;
    FMongoEnv: TMongoEnv;
    FMongoConnection: TMongoConnection;
    procedure CommandUpdateExecute(const ACommandText: String; const AParams: TParams);
    procedure CommandInsertExecute(const ACommandText: String; const AParams: TParams);
    procedure CommandDeleteExecute(const ACommandText: String; const AParams: TParams);
  public
    constructor Create(const AConnection: TComponent;
      const ADriverName: TDriverName); override;
    destructor Destroy; override;
    procedure Connect; override;
    procedure Disconnect; override;
    procedure ExecuteDirect(const ASQL: String); override;
    procedure ExecuteDirect(const ASQL: String; const AParams: TParams); override;
    procedure ExecuteScript(const AScript: String); override;
    procedure AddScript(const AScript: String); override;
    procedure ExecuteScripts; override;
    function IsConnected: Boolean; override;
    function InTransaction: Boolean; override;
    function CreateQuery: IDBQuery; override;
    function CreateDataSet(const ASQL: String): IDBResultSet; override;
  end;

  TDriverQueryMongoFireDAC = class(TDriverQuery)
  private
    FConnection: TFDConnection;
    FFDMongoQuery: TFDMongoQuery;
    FMongoConnection: TMongoConnection;
    FMongoEnv: TMongoEnv;
  protected
    procedure SetCommandText(ACommandText: String); override;
    function GetCommandText: String; override;
  public
    constructor Create(AConnection: TFDConnection; AMongoConnection: TMongoConnection;
      AMongoEnv: TMongoEnv);
    destructor Destroy; override;
    procedure ExecuteDirect; override;
    function ExecuteQuery: IDBResultSet; override;
  end;

  TDriverResultSetMongoFireDAC = class(TDriverResultSet<TFDMongoQuery>)
  public
    constructor Create(ADataSet: TFDMongoQuery); override;
    destructor Destroy; override;
    function NotEof: Boolean; override;
    function GetFieldValue(const AFieldName: String): Variant; overload; override;
    function GetFieldValue(const AFieldIndex: UInt16): Variant; overload; override;
    function GetFieldType(const AFieldName: String): TFieldType; overload; override;
    function GetField(const AFieldName: String): TField; override;
  end;

implementation

uses
  ormbr.utils;

{ TDriverMongoFireDAC }

constructor TDriverMongoFireDAC.Create(const AConnection: TComponent;
  const ADriverName: TDriverName);
begin
  inherited;
  FConnection := AConnection as TFDConnection;
  FDriverName := ADriverName;
  FMongoConnection := TMongoConnection(FConnection.CliObj);
  FMongoEnv := FMongoConnection.Env;

//  FSQLScript  := TFDMongoQuery.Create(nil);
//  try
//    FSQLScript.Connection := FConnection;
//    FSQLScript.DatabaseName := FConnection.Params.Database;
//  except
//    FSQLScript.Free;
//    raise;
//  end;
end;

destructor TDriverMongoFireDAC.Destroy;
begin
  FConnection := nil;
//  FSQLScript.Free;
  inherited;
end;

procedure TDriverMongoFireDAC.Disconnect;
begin
  inherited;
  FConnection.Connected := False;
end;

procedure TDriverMongoFireDAC.ExecuteDirect(const ASQL: String);
begin
  inherited;
  raise Exception.Create('Command [ExecuteDirect()] not supported for NoSQL MongoDB database!');
//  FConnection.ExecSQL(ASQL);
end;

procedure TDriverMongoFireDAC.ExecuteDirect(const ASQL: String;
  const AParams: TParams);
var
  LCommand: String;
begin
  LCommand := TUtilSingleton
                .GetInstance
                  .ParseCommandNoSQL('command', ASQL);
  if LCommand = 'insert' then
    CommandInsertExecute(ASQL, Aparams)
  else
  if LCommand = 'update' then
    CommandUpdateExecute(ASQL, AParams)
  else
  if LCommand = 'delete' then
    CommandDeleteExecute(ASQL, AParams);
end;

procedure TDriverMongoFireDAC.ExecuteScript(const AScript: String);
begin
  inherited;
//  FSQLScript.QMatch := ASQL;
//  FSQLScript.Execute;
  raise Exception
          .Create('Command [ExecuteScript()] not supported for NoSQL MongoDB database!');
end;

procedure TDriverMongoFireDAC.ExecuteScripts;
begin
  inherited;
  raise Exception
          .Create('Command [ExecuteScripts()] not supported for NoSQL MongoDB database!');
//  if Length(FSQLScript.QMatch) > 0 then
//  begin
//    try
//      FSQLScript.Execute;
//    finally
//      FSQLScript.QMatch := '';
//    end;
//  end;
end;

procedure TDriverMongoFireDAC.AddScript(const AScript: String);
begin
  inherited;
//  FSQLScript.QMatch := ASQL;
  raise Exception
          .Create('Command [AddScript()] not supported for NoSQL MongoDB database!');
end;

procedure TDriverMongoFireDAC.CommandDeleteExecute(const ACommandText: String;
  const AParams: TParams);
var
  LMongoSelector: TMongoSelector;
  LUtil: IUtilSingleton;
begin
  LMongoSelector := TMongoSelector.Create(FMongoEnv);
  LUtil := TUtilSingleton.GetInstance;
  try
    LMongoSelector.Match(LUtil.ParseCommandNoSQL('json', ACommandText));
//    LMongoSelector.FinalMatchBSON.AsJSON;
    FMongoConnection[FConnection.Params.Database]
                    [LUtil.ParseCommandNoSQL('collection', ACommandText)]
      .Remove(LMongoSelector);
  finally
    LMongoSelector.Free;
  end;
end;

procedure TDriverMongoFireDAC.CommandInsertExecute(const ACommandText: String;
  const AParams: TParams);
var
  LMongoInsert: TMongoInsert;
  LUtil: IUtilSingleton;
begin
  LMongoInsert := TMongoInsert.Create(FMongoEnv);
  LUtil := TUtilSingleton.GetInstance;
  try
    LMongoInsert
      .Values(LUtil.ParseCommandNoSQL('json', ACommandText));
//    LMongoInsert.FinalValuesBSON.AsJSON;
    FMongoConnection[FConnection.Params.Database]
                    [LUtil.ParseCommandNoSQL('collection', ACommandText)]
      .Insert(LMongoInsert)
  finally
    LMongoInsert.Free;
  end;
end;

procedure TDriverMongoFireDAC.CommandUpdateExecute(const ACommandText: String;
  const AParams: TParams);
var
  LMongoUpdate: TMongoUpdate;
  LUtil: IUtilSingleton;
begin
  LMongoUpdate := TMongoUpdate.Create(FMongoEnv);
  LUtil := TUtilSingleton.GetInstance;
  try
    LMongoUpdate
      .Match(LUtil.ParseCommandNoSQL('filter', ACommandText));
    LMongoUpdate
      .Modify(LUtil.ParseCommandNoSQL('json', ACommandText));
//    LMongoUpdate.FinalModifyBSON.AsJSON;
    FMongoConnection[FConnection.Params.Database]
                    [LUtil.ParseCommandNoSQL('collection', ACommandText)]
      .Update(LMongoUpdate);
  finally
    LMongoUpdate.Free;
  end;
end;

procedure TDriverMongoFireDAC.Connect;
begin
  inherited;
  FConnection.Connected := True;
end;

function TDriverMongoFireDAC.InTransaction: Boolean;
begin
  Result := FConnection.InTransaction;
end;

function TDriverMongoFireDAC.IsConnected: Boolean;
begin
  inherited;
  Result := FConnection.Connected;
end;

function TDriverMongoFireDAC.CreateQuery: IDBQuery;
begin
  Result := TDriverQueryMongoFireDAC.Create(FConnection, FMongoConnection, FMongoEnv);
end;

function TDriverMongoFireDAC.CreateDataSet(const ASQL: String): IDBResultSet;
var
  LDBQuery: IDBQuery;
begin
  LDBQuery := TDriverQueryMongoFireDAC.Create(FConnection, FMongoConnection, FMongoEnv);
  LDBQuery.CommandText := ASQL;
  Result := LDBQuery.ExecuteQuery;
end;

{ TDriverDBExpressQuery }

constructor TDriverQueryMongoFireDAC.Create(AConnection: TFDConnection;
  AMongoConnection: TMongoConnection; AMongoEnv: TMongoEnv);
begin
  FConnection := AConnection;
  FMongoConnection := AMongoConnection;
  FMongoEnv := AMongoEnv;
  if AConnection = nil then
    Exit;

  FFDMongoQuery := TFDMongoQuery.Create(nil);
  try
    FFDMongoQuery.Connection := AConnection;
    FFDMongoQuery.DatabaseName := AConnection.Params.Database;
  except
    FFDMongoQuery.Free;
    raise;
  end;
end;

destructor TDriverQueryMongoFireDAC.Destroy;
begin
  FConnection := nil;
  FFDMongoQuery.Free;
  inherited;
end;

function TDriverQueryMongoFireDAC.ExecuteQuery: IDBResultSet;
var
  LResultSet: TFDMongoQuery;
  LLimit, LSkip: UInt16;
  LUtil: IUtilSingleton;
begin
  LResultSet := TFDMongoQuery.Create(nil);
  LResultSet.CachedUpdates := True;
  LUtil := TUtilSingleton.GetInstance;
  try
    LResultSet.Connection := FFDMongoQuery.Connection;
    LResultSet.DatabaseName := FFDMongoQuery.Connection.Params.Database;
    LResultSet.CollectionName := LUtil.ParseCommandNoSQL('collection', FFDMongoQuery.QMatch);
    LResultSet.QMatch := LUtil.ParseCommandNoSQL('filter', FFDMongoQuery.QMatch);
    LResultSet.QSort := LUtil.ParseCommandNoSQL('sort', FFDMongoQuery.QMatch);
    LLimit := StrToIntDef(LUtil.ParseCommandNoSQL('limit', FFDMongoQuery.QMatch), 0);
    LSkip := StrToIntDef(LUtil.ParseCommandNoSQL('skip', FFDMongoQuery.QMatch), 0);
    if LLimit > 0 then
      LResultSet.Query.Limit(LLimit);
    if LSkip > 0 then
      LResultSet.Query.Skip(LSkip);
    LResultSet.QProject := '{_id:0}';
    LResultSet.Open;
//    LResultSet.Query.FinalQueryBSON.AsJSON;
  except
    LResultSet.Free;
    raise;
  end;
  Result := TDriverResultSetMongoFireDAC.Create(LResultSet);
  if LResultSet.RecordCount = 0 then
    Result.FetchingAll := True;
end;

function TDriverQueryMongoFireDAC.GetCommandText: String;
begin
  Result := FFDMongoQuery.QMatch;
end;

procedure TDriverQueryMongoFireDAC.SetCommandText(ACommandText: String);
begin
  inherited;
  FFDMongoQuery.QMatch := ACommandText;
end;

procedure TDriverQueryMongoFireDAC.ExecuteDirect;
begin
//  FFDMongoQuery.Execute;
  raise Exception
          .Create('Command [ExecuteDirect()] not supported for NoSQL MongoDB database!');
end;

{ TDriverResultSetMongoFireDAC }

constructor TDriverResultSetMongoFireDAC.Create(ADataSet: TFDMongoQuery);
begin
  FDataSet := ADataSet;
  inherited;
end;

destructor TDriverResultSetMongoFireDAC.Destroy;
begin
  FDataSet.Free;
  inherited;
end;

function TDriverResultSetMongoFireDAC.GetFieldValue(
  const AFieldName: String): Variant;
var
  LField: TField;
begin
  LField := FDataSet.FieldByName(AFieldName);
  Result := GetFieldValue(LField.Index);
end;

function TDriverResultSetMongoFireDAC.GetFieldType(
  const AFieldName: String): TFieldType;
begin
  Result := FDataSet.FieldByName(AFieldName).DataType;
end;

function TDriverResultSetMongoFireDAC.GetFieldValue(
  const AFieldIndex: Uint16): Variant;
begin
  if AFieldIndex > FDataSet.FieldCount - 1 then
    Exit(Variants.Null);

  if FDataSet.Fields[AFieldIndex].IsNull then
    Result := Variants.Null
  else
    Result := FDataSet.Fields[AFieldIndex].Value;
end;

function TDriverResultSetMongoFireDAC.GetField(
  const AFieldName: String): TField;
begin
  Result := FDataSet.FieldByName(AFieldName);
end;

function TDriverResultSetMongoFireDAC.NotEof: Boolean;
begin
  if not FFirstNext then
    FFirstNext := True
  else
    FDataSet.Next;
  Result := not FDataSet.Eof;
end;

end.
