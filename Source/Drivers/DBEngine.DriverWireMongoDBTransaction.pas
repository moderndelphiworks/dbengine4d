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

unit DBEngine.DriverWireMongoDBTransaction;

interface

uses
  DB,
  Classes,
  // DBE
  DBE.DriverConnection,
  DBE.FactoryInterfaces,
  MongoWireConnection;

type
  // Classe de conex�o concreta com MongoWire
  TDriverMongoWireTransaction = class(TDriverTransaction)
  protected
    FConnection: TMongoWireConnection;
  public
    constructor Create(AConnection: TComponent); override;
    destructor Destroy; override;
    procedure StartTransaction; override;
    procedure Commit; override;
    procedure Rollback; override;
    function InTransaction: Boolean; override;
  end;

implementation

{ TDriverMongoWireTransaction }

constructor TDriverMongoWireTransaction.Create(AConnection: TComponent);
begin
  FConnection := AConnection as TMongoWireConnection;
end;

destructor TDriverMongoWireTransaction.Destroy;
begin
  FConnection := nil;
  inherited;
end;

function TDriverMongoWireTransaction.InTransaction: Boolean;
begin
  Result := False; //FConnection.InTransaction;
end;

procedure TDriverMongoWireTransaction.StartTransaction;
begin
  inherited;
//  FConnection.StartTransaction;
end;

procedure TDriverMongoWireTransaction.Commit;
begin
  inherited;
//  FConnection.Commit;
end;

procedure TDriverMongoWireTransaction.Rollback;
begin
  inherited;
//  FConnection.Rollback;
end;

end.
