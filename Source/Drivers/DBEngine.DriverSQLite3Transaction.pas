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

unit DBEngine.DriverSQLite3Transaction;

interface

uses
  DB,
  Classes,
  SQLiteTable3,
  // DBE
  DBE.DriverConnection,
  DBE.FactoryInterfaces;

type
  // Classe de conex�o concreta com dbExpress
  TDriverSQLite3Transaction = class(TDriverTransaction)
  protected
    FConnection: TSQLiteDatabase;
  public
    constructor Create(AConnection: TComponent); override;
    destructor Destroy; override;
    procedure StartTransaction; override;
    procedure Commit; override;
    procedure Rollback; override;
    function InTransaction: Boolean; override;
  end;

implementation

{ TDriverSQLiteTransaction3 }

constructor TDriverSQLite3Transaction.Create(AConnection: TComponent);
begin
  FConnection := AConnection as TSQLiteDatabase;;
end;

destructor TDriverSQLite3Transaction.Destroy;
begin
  FConnection := nil;
  inherited;
end;

function TDriverSQLite3Transaction.InTransaction: Boolean;
begin
  Result := FConnection.IsTransactionOpen;
end;

procedure TDriverSQLite3Transaction.StartTransaction;
begin
  inherited;
  FConnection.BeginTransaction;
end;

procedure TDriverSQLite3Transaction.Commit;
begin
  inherited;
  FConnection.Commit;
end;

procedure TDriverSQLite3Transaction.Rollback;
begin
  inherited;
  FConnection.Rollback;
end;

end.
