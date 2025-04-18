unit uPrincipal;

interface

uses
  JclIDEUtils, JclCompilerUtils, ACBrUtil,

  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, Buttons, pngimage, ShlObj,
  uFrameLista, IOUtils,
  Types, JvComponentBase, JvCreateProcess, JvExControls, JvAnimatedImage,
  JvGIFCtrl, JvWizard, JvWizardRouteMapNodes, CheckLst;

type
  TDestino = (tdSystem, tdDelphi, tdNone);

  TfrmPrincipal = class(TForm)
    wizPrincipal: TJvWizard;
    wizMapa: TJvWizardRouteMapNodes;
    wizPgConfiguracao: TJvWizardInteriorPage;
    wizPgInstalacao: TJvWizardInteriorPage;
    wizPgFinalizar: TJvWizardInteriorPage;
    wizPgInicio: TJvWizardWelcomePage;
    Label4: TLabel;
    Label5: TLabel;
    edtPlatform: TComboBox;
    Label2: TLabel;
    edtDirDestino: TEdit;
    Label6: TLabel;
    imgLogomarca: TImage;
    lstMsgInstalacao: TListBox;
    pnlTopo: TPanel;
    Label9: TLabel;
    btnSelecDirInstall: TSpeedButton;
    Label3: TLabel;
    pgbInstalacao: TProgressBar;
    lblUrl: TLabel;
    lblUrlForum1: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    btnInstalar: TSpeedButton;
    btnVisualizarLogCompilacao: TSpeedButton;
    pnlInfoCompilador: TPanel;
    wizPgPacotes: TJvWizardInteriorPage;
    lbInfo: TListBox;
    chkDeixarSomenteLIB: TCheckBox;
    JvCreateProcess1: TJvCreateProcess;
    clbDelphiVersion: TCheckListBox;
    framePacotes1: TframePacotes;
    Label23: TLabel;
    edtDelphiVersion: TComboBox;
    Label1: TLabel;
    Label8: TLabel;
    ckbUsarArquivoConfig: TCheckBox;
    Label7: TLabel;
    procedure imgPropaganda1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure edtDelphiVersionChange(Sender: TObject);
    procedure wizPgInicioNextButtonClick(Sender: TObject; var Stop: Boolean);
    procedure URLClick(Sender: TObject);
    procedure btnSelecDirInstallClick(Sender: TObject);
    procedure wizPrincipalCancelButtonClick(Sender: TObject);
    procedure wizPrincipalFinishButtonClick(Sender: TObject);
    procedure wizPgConfiguracaoNextButtonClick(Sender: TObject;
      var Stop: Boolean);
    procedure btnSVNCheckoutUpdateClick(Sender: TObject);
    procedure btnInstalarClick(Sender: TObject);
    procedure wizPgObterFontesNextButtonClick(Sender: TObject;
      var Stop: Boolean);
    procedure wizPgInstalacaoNextButtonClick(Sender: TObject;
      var Stop: Boolean);
    procedure btnVisualizarLogCompilacaoClick(Sender: TObject);
    procedure wizPgInstalacaoEnterPage(Sender: TObject;
      const FromPage: TJvWizardCustomPage);
    procedure clbDelphiVersionClick(Sender: TObject);
    procedure Label8Click(Sender: TObject);
    procedure Label7Click(Sender: TObject);
  private
    FCountErros: Integer;
    oORMBr: TJclBorRADToolInstallations;
    iVersion: Integer;
    tPlatform: TJclBDSPlatform;
    sDirRoot: String;
    sDirLibrary: String;
    sDirPackage: String;
    sDestino   : TDestino;
    sPathBin   : String;
    FPacoteAtual: TFileName;
    procedure BeforeExecute(Sender: TJclBorlandCommandLineTool);
    procedure AddLibrarySearchPath;
    procedure OutputCallLine(const Text: String);
    procedure SetPlatformSelected;
    procedure CreateDirectoryLibrarysNotExist;
    procedure GravarConfiguracoes;
    procedure LerConfiguracoes;
    function PathApp: String;
    function PathArquivoIni: String;
    function PathArquivoLog: String;
    function PathSystem: String;
    procedure CopiarArquivoTo(ADestino : TDestino; const ANomeArquivo: String);
    procedure ExtrairDiretorioPacote(NomePacote: String);
    procedure AddLibraryPathToDelphiPath(const APath, AProcurarRemover: String);
    procedure FindDirs(ADirRoot: String; bAdicionar: Boolean = True);
    procedure DeixarSomenteLib;
    procedure RemoverDiretoriosEPacotesAntigos;
    {$IFNDEF DEBUG}
    function RunAsAdminAndWaitForCompletion(hWnd: HWND; filename: String): Boolean;
    {$ENDIF}
    procedure GetDriveLetters(AList: TStrings);
    procedure MostraDadosVersao;
    function GetPathORMBrInc: TFileName;
  public

  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

uses
  SVN_Class, FileCtrl, ShellApi, IniFiles, StrUtils, Math, Registry;

{$R *.dfm}

{$IFNDEF DEBUG}
function TfrmPrincipal.RunAsAdminAndWaitForCompletion(hWnd: HWND; filename: String): Boolean;
{
    See Step 3: Redesign for UAC Compatibility (UAC)
    http://msdn.microsoft.com/en-us/library/bb756922.aspx
}
var
  sei: TShellExecuteInfo;
  ExitCode: DWORD;
begin
  ZeroMemory(@sei, SizeOf(sei));
  sei.cbSize       := SizeOf(TShellExecuteInfo);
  sei.Wnd          := hwnd;
  sei.fMask        := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_FLAG_NO_UI or SEE_MASK_NOCLOSEPROCESS;
  sei.lpVerb       := PWideChar('runas');
  sei.lpFile       := PWideChar(Filename);
  sei.lpParameters := PWideChar('');
  sei.nShow        := SW_HIDE;

  if ShellExecuteEx(@sei) then
  begin
    repeat
      Application.ProcessMessages;
      GetExitCodeProcess(sei.hProcess, ExitCode) ;
    until (ExitCode <> STILL_ACTIVE) or  Application.Terminated;
  end;
end;
{$ENDIF}

procedure TfrmPrincipal.ExtrairDiretorioPacote(NomePacote: String);

  procedure FindDirPackage(sDir, sPacote: String);
  var
    oDirList: TSearchRec;
    iRet: Integer;
    sDirDpk: String;
  begin
    sDir := IncludeTrailingPathDelimiter(sDir);
    if not DirectoryExists(sDir) then
      Exit;

    if SysUtils.FindFirst(sDir + '*.*', faAnyFile, oDirList) = 0 then
    begin
      try
        repeat

          if (oDirList.Name = '.') or
             (oDirList.Name = '..') or
             (oDirList.Name = '__history') or
             (oDirList.Name = '__recovery') or
             (oDirList.Name = 'Win32') or
             (oDirList.Name = 'Win64') then
            Continue;

          //if oDirList.Attr = faDirectory then
          if DirectoryExists(sDir + oDirList.Name) then
            FindDirPackage(sDir + oDirList.Name, sPacote)
          else
          begin
            if UpperCase(oDirList.Name) = UpperCase(sPacote) then
              sDirPackage := IncludeTrailingPathDelimiter(sDir);
          end;

        until SysUtils.FindNext(oDirList) <> 0;
      finally
        SysUtils.FindClose(oDirList);
      end;
    end;
  end;

begin
   sDirPackage := '';
   FindDirPackage(IncludeTrailingPathDelimiter(sDirRoot) + 'Projects\Wizard', NomePacote);
   FindDirPackage(IncludeTrailingPathDelimiter(sDirRoot) + 'Projects\Components', NomePacote);
   FindDirPackage(IncludeTrailingPathDelimiter(sDirRoot) + 'Projects\Components\MongoWire', NomePacote);
end;

// retornar o path do aplicativo
function TfrmPrincipal.PathApp: String;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

// retornar o caminho completo para o arquivo .ini de configura��es
function TfrmPrincipal.PathArquivoIni: String;
var
  NomeApp: String;
begin
  NomeApp := ExtractFileName(ParamStr(0));
  Result := PathApp + ChangeFileExt(NomeApp, '.ini');
end;

// retornar o caminho completo para o arquivo de logs
function TfrmPrincipal.PathArquivoLog: String;
begin
  Result := PathApp + 'log_' + StringReplace(edtDelphiVersion.Text, ' ', '_', [rfReplaceAll]) + '.txt';
end;

// retorna o diret�rio de sistema atual
function TfrmPrincipal.PathSystem: String;
var
  strTmp: array[0..MAX_PATH] of char;
  DirWindows: String;
const
  SYS_64 = 'SysWOW64';
  SYS_32 = 'System32';
begin
  Result := '';

  //SetLength(strTmp, MAX_PATH);
  if Windows.GetWindowsDirectory(strTmp, MAX_PATH) > 0 then
  begin
    DirWindows := Trim(StrPas(strTmp));
    DirWindows := IncludeTrailingPathDelimiter(DirWindows);

    if DirectoryExists(DirWindows + SYS_64) then
      Result := DirWindows + SYS_64
    else
    if DirectoryExists(DirWindows + SYS_32) then
      Result := DirWindows + SYS_32
    else
      raise EFileNotFoundException.Create('Diret�rio de sistema n�o encontrado.');
  end
  else
    raise EFileNotFoundException.Create('Ocorreu um erro ao tentar obter o diret�rio do windows.');
end;

procedure TfrmPrincipal.CopiarArquivoTo(ADestino : TDestino; const ANomeArquivo: String);
var
  PathOrigem: String;
  PathDestino: String;
  DirSystem: String;
  DirORMBr: String;
begin
  case ADestino of
    tdSystem: DirSystem := Trim(PathSystem);
    tdDelphi: DirSystem := sPathBin;
  end;

  DirORMBr := IncludeTrailingPathDelimiter(edtDirDestino.Text);

  if DirSystem <> EmptyStr then
    DirSystem := IncludeTrailingPathDelimiter(DirSystem)
  else
    raise EFileNotFoundException.Create('Diret�rio de sistema n�o encontrado.');

  PathOrigem  := DirORMBr + 'DLLs\' + ANomeArquivo;
  PathDestino := DirSystem + ExtractFileName(ANomeArquivo);

  if FileExists(PathOrigem) and not(FileExists(PathDestino)) then
  begin
    if not CopyFile(PWideChar(PathOrigem), PWideChar(PathDestino), True) then
    begin
      raise EFilerError.CreateFmt(
        'Ocorreu o seguinte erro ao tentar copiar o arquivo "%s": %d - %s', [
        ANomeArquivo, GetLastError, SysErrorMessage(GetLastError)
      ]);
    end;
  end;
end;

// ler o arquivo .ini de configura��es e setar os campos com os valores lidos
procedure TfrmPrincipal.Label7Click(Sender: TObject);
begin
  ckbUsarArquivoConfig.Checked := not ckbUsarArquivoConfig.Checked;
end;

procedure TfrmPrincipal.Label8Click(Sender: TObject);
begin
  chkDeixarSomenteLIB.Checked := not chkDeixarSomenteLIB.Checked;
end;

procedure TfrmPrincipal.LerConfiguracoes;
var
  ArqIni: TIniFile;
  I: Integer;
begin
  ArqIni := TIniFile.Create(PathArquivoIni);
  try
    edtDirDestino.Text := ArqIni.ReadString('CONFIG', 'DiretorioInstalacao', ExtractFilePath(ParamStr(0)));
    edtPlatform.ItemIndex := edtPlatform.Items.IndexOf('Win32');
//    edtDelphiVersion.ItemIndex  := edtDelphiVersion.Items.IndexOf(ArqIni.ReadString('CONFIG', 'DelphiVersao', ''));
    chkDeixarSomenteLIB.Checked    := ArqIni.ReadBool('CONFIG','DexarSomenteLib',False);

    if Trim(edtDelphiVersion.Text) = '' then
      edtDelphiVersion.ItemIndex := 0;

    edtDelphiVersionChange(edtDelphiVersion);

    for I := 0 to framePacotes1.Pacotes.Count - 1 do
      if framePacotes1.Pacotes[I].Enabled then
        framePacotes1.Pacotes[I].Checked := ArqIni.ReadBool('PACOTES', framePacotes1.Pacotes[I].Hint, False);
  finally
    ArqIni.Free;
  end;
end;

procedure TfrmPrincipal.MostraDadosVersao;
begin
  // mostrar ao usu�rio as informa��es de compila��o
  lbInfo.Clear;
  with lbInfo.Items do
  begin
    Clear;
    Add(edtDelphiVersion.Text + ' ' + edtPlatform.Text);
    Add('Dir. Instala��o  : ' + edtDirDestino.Text);
    Add('Dir. Bibliotecas : ' + sDirLibrary);
  end;
end;

// gravar as configura��es efetuadas pelo usu�rio
procedure TfrmPrincipal.GravarConfiguracoes;
var
  ArqIni: TIniFile;
  I: Integer;
begin
  ArqIni := TIniFile.Create(PathArquivoIni);
  try
    ArqIni.WriteString('CONFIG', 'DiretorioInstalacao', edtDirDestino.Text);
//    ArqIni.WriteString('CONFIG', 'DelphiVersao', edtDelphiVersion.Text);
    ArqIni.WriteString('CONFIG', 'Plataforma', edtPlatform.Text);
    ArqIni.WriteBool('CONFIG','DexarSomenteLib', chkDeixarSomenteLIB.Checked);

    for I := 0 to framePacotes1.Pacotes.Count - 1 do
      if framePacotes1.Pacotes[I].Enabled then
        ArqIni.WriteBool('PACOTES', framePacotes1.Pacotes[I].Hint, framePacotes1.Pacotes[I].Checked);
  finally
    ArqIni.Free;
  end;
end;

// cria��o dos diret�rios necess�rios
procedure TfrmPrincipal.CreateDirectoryLibrarysNotExist;
begin
  // Checa se existe diret�rio da plataforma
  if not DirectoryExists(sDirLibrary) then
    ForceDirectories(sDirLibrary);
end;

procedure TfrmPrincipal.DeixarSomenteLib;
  procedure Copiar(const Extensao : String);
  var
    ListArquivos: TStringDynArray;
    Arquivo : String;
    i: integer;
  begin
    ListArquivos := TDirectory.GetFiles(IncludeTrailingPathDelimiter(sDirRoot) + 'Source', Extensao ,TSearchOption.soAllDirectories ) ;
    for i := Low(ListArquivos) to High(ListArquivos) do
    begin
      Arquivo := ExtractFileName(ListArquivos[i]);
      CopyFile(PWideChar(ListArquivos[i]), PWideChar(IncludeTrailingPathDelimiter(sDirLibrary) + Arquivo), False);
    end;
  end;
begin
  // remover os path com o segundo parametro
  FindDirs(IncludeTrailingPathDelimiter(sDirRoot) + 'Source', False);

  Copiar('*.dcr');
  Copiar('*.res');
  Copiar('*.dfm');
  Copiar('*.ini');
  Copiar('*.inc');
end;

procedure TfrmPrincipal.AddLibraryPathToDelphiPath(const APath: String; const AProcurarRemover: String);
const
  cs: PChar = 'Environment Variables';
var
  lParam, wParam: Integer;
  aResult: Cardinal;
  ListaPaths: TStringList;
  I: Integer;
  PathsAtuais: String;
  PathFonte: String;
begin
  with oORMBr.Installations[iVersion] do
  begin
    // tentar ler o path configurado na ide do delphi, se n�o existir ler
    // a atual para complementar e fazer o override
    PathsAtuais := Trim(EnvironmentVariables.Values['PATH']);
    if PathsAtuais = '' then
      PathsAtuais := GetEnvironmentVariable('PATH');

    // manipular as Strings
    ListaPaths := TStringList.Create;
    try
      ListaPaths.Clear;
      ListaPaths.Delimiter       := ';';
      ListaPaths.StrictDelimiter := True;
      ListaPaths.DelimitedText   := PathsAtuais;

      // verificar se existe algo do ORMBr e remover do environment variable PATH do delphi
      if Trim(AProcurarRemover) <> '' then
      begin
        for I := ListaPaths.Count - 1 downto 0 do
        begin
         if Pos(AnsiUpperCase(AProcurarRemover), AnsiUpperCase(ListaPaths[I])) > 0 then
           ListaPaths.Delete(I);
        end;
      end;

      // adicionar o path
      ListaPaths.Add(APath);

      // escrever a variavel no override da ide
      ConfigData.WriteString(cs, 'PATH', ListaPaths.DelimitedText);

      // enviar um broadcast de atualiza��o para o windows
      wParam := 0;
      lParam := LongInt(cs);
      SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, wParam, lParam, SMTO_NORMAL, 4000, aResult);
      if aResult <> 0 then
        raise Exception.create('Ocorreu um erro ao tentar configurar o path: ' + SysErrorMessage(aResult));
    finally
      ListaPaths.Free;
    end;
  end;
end;

procedure TfrmPrincipal.FindDirs(ADirRoot: String; bAdicionar: Boolean = True);
var
  oDirList: TSearchRec;

  function EProibido(const ADir: String): Boolean;
  const
    LISTA_PROIBIDOS: ARRAY[0..5] OF String = (
      'quick', 'rave', 'laz', 'VerificarNecessidade', '__history', '__recovery'
    );
  var
    Str: String;
  begin
    Result := False;
    for str in LISTA_PROIBIDOS do
    begin
      Result := Pos(AnsiUpperCase(str), AnsiUpperCase(ADir)) > 0;
      if Result then
        Break;
    end;
  end;

begin
  ADirRoot := IncludeTrailingPathDelimiter(ADirRoot);

  if FindFirst(ADirRoot + '*.*', faDirectory, oDirList) = 0 then
  begin
     try
       repeat
          if ((oDirList.Attr and faDirectory) <> 0) and
              (oDirList.Name <> '.')                and
              (oDirList.Name <> '..')               and
              (not EProibido(oDirList.Name)) then
          begin
             with oORMBr.Installations[iVersion] do
             begin
               if bAdicionar then
               begin
                  AddToLibrarySearchPath(ADirRoot + oDirList.Name, tPlatform);
                  AddToLibraryBrowsingPath(ADirRoot + oDirList.Name, tPlatform);
               end
               else
                  RemoveFromLibrarySearchPath(ADirRoot + oDirList.Name, tPlatform);
             end;
             //-- Procura subpastas
             FindDirs(ADirRoot + oDirList.Name, bAdicionar);
          end;
       until FindNext(oDirList) <> 0;
     finally
       SysUtils.FindClose(oDirList)
     end;
  end;
end;

// adicionar o paths ao library path do delphi
procedure TfrmPrincipal.AddLibrarySearchPath;
begin
  FindDirs(IncludeTrailingPathDelimiter(sDirRoot) + 'Source');

  // --
  with oORMBr.Installations[iVersion] do
  begin
    AddToLibraryBrowsingPath(sDirLibrary, tPlatform);
    AddToLibrarySearchPath(sDirLibrary, tPlatform);
    AddToDebugDCUPath(sDirLibrary, tPlatform);
  end;

  // -- adicionar a library path ao path do windows
  AddLibraryPathToDelphiPath(sDirLibrary, 'ormbr');
end;

// setar a plataforma de compila��o
procedure TfrmPrincipal.SetPlatformSelected;
var
  sVersao: String;
  sTipo: String;
begin
  iVersion := edtDelphiVersion.ItemIndex;
  sVersao  := AnsiUpperCase(oORMBr.Installations[iVersion].VersionNumberStr);
  sDirRoot := IncludeTrailingPathDelimiter(edtDirDestino.Text);

  sTipo := 'Lib\Delphi\';

  if edtPlatform.ItemIndex = 0 then // Win32
  begin
    tPlatform   := bpWin32;
    sDirLibrary := sDirRoot + sTipo + 'Lib' + sVersao;
  end
  else
  if edtPlatform.ItemIndex = 1 then // Win64
  begin
    tPlatform   := bpWin64;
    sDirLibrary := sDirRoot + sTipo + 'Lib' + sVersao + 'x64';
  end;
end;

// Evento disparado a cada a��o do instalador
procedure TfrmPrincipal.OutputCallLine(const Text: String);
begin
  // remover a warnings de convers�o de String (delphi 2010 em diante)
  // as diretivas -W e -H n�o removem estas mensagens
  if (pos('Warning: W1057', Text) <= 0) and ((pos('Warning: W1058', Text) <= 0)) then
    WriteToTXT(PathArquivoLog, Text);
end;

// evento para setar os par�metros do compilador antes de compilar
procedure TfrmPrincipal.BeforeExecute(Sender: TJclBorlandCommandLineTool);
var
  LArquivoCfg: TFilename;
begin
  // limpar os par�metros do compilador
  Sender.Options.Clear;

  // n�o utilizar o dcc32.cfg
  if (oORMBr.Installations[iVersion].SupportsNoConfig) and (not ckbUsarArquivoConfig.Checked) then
    Sender.Options.Add('--no-config');

  // -B = Build all units
  Sender.Options.Add('-B');
  // O+ = Optimization
  Sender.Options.Add('-$O-');
  // W- = Generate stack frames
  Sender.Options.Add('-$W+');
  // Y+ = Symbol reference info
  Sender.Options.Add('-$Y-');
  // -M = Make modified units
  Sender.Options.Add('-M');
  // -Q = Quiet compile
  Sender.Options.Add('-Q');
  // n�o mostrar warnings
  Sender.Options.Add('-H-');
  // n�o mostrar hints
  Sender.Options.Add('-W-');
  // -D<syms> = Define conditionals
  Sender.Options.Add('-DRELEASE');
  // -U<paths> = Unit directories
  Sender.AddPathOption('U', oORMBr.Installations[iVersion].LibFolderName[tPlatform]);
  Sender.AddPathOption('U', oORMBr.Installations[iVersion].LibrarySearchPath[tPlatform]);
  Sender.AddPathOption('U', sDirLibrary);
  // -I<paths> = Include directories
  Sender.AddPathOption('I', oORMBr.Installations[iVersion].LibrarySearchPath[tPlatform]);
  // -R<paths> = Resource directories
  Sender.AddPathOption('R', oORMBr.Installations[iVersion].LibrarySearchPath[tPlatform]);
  // -N0<path> = unit .dcu output directory
  Sender.AddPathOption('N0', sDirLibrary);
  Sender.AddPathOption('LE', sDirLibrary);
  Sender.AddPathOption('LN', sDirLibrary);
  //
  with oORMBr.Installations[iVersion] do
  begin
     // -- Path para instalar os pacotes do Rave no D7, nas demais vers�es
     // -- o path existe.
     if VersionNumberStr = 'd7' then
        Sender.AddPathOption('U', oORMBr.Installations[iVersion].RootDir + '\Rave5\Lib');

     // -- Na vers�o XE2 por motivo da nova tecnologia FireMonkey, deve-se adicionar
     // -- os prefixos dos nomes, para identificar se ser� compilado para VCL ou FMX
     if VersionNumberStr = 'd16' then
        Sender.Options.Add('-NSData.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win;Bde;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;System;Xml;Data;Datasnap;Web;Soap;Winapi;System.Win');

     if MatchText(VersionNumberStr, ['d17','d18','d19','d20','d21','d22','d23','d24','d25','d26']) then
        Sender.Options.Add('-NSWinapi;System.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win;Bde;System;Xml;Data;Datasnap;Web;Soap;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell,Ibx');
  end;
  if (ckbUsarArquivoConfig.Checked) then
  begin
    LArquivoCfg := ChangeFileExt(FPacoteAtual, '.cfg');
    Sender.Options.SaveToFile(LArquivoCfg);
    Sender.Options.Clear;
  end;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
var
  iFor: Integer;
begin
  iVersion    := -1;
  sDirRoot    := '';
  sDirLibrary := '';
  sDirPackage := '';

  oORMBr := TJclBorRADToolInstallations.Create;

  // popular o combobox de vers�es do delphi instaladas na m�quina
  for iFor := 0 to oORMBr.Count - 1 do
  begin
    if      oORMBr.Installations[iFor].VersionNumberStr = 'd3' then
      edtDelphiVersion.Items.Add('Delphi 3')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd4' then
      edtDelphiVersion.Items.Add('Delphi 4')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd5' then
      edtDelphiVersion.Items.Add('Delphi 5')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd6' then
      edtDelphiVersion.Items.Add('Delphi 6')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd7' then
      edtDelphiVersion.Items.Add('Delphi 7')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd9' then
      edtDelphiVersion.Items.Add('Delphi 2005')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd10' then
      edtDelphiVersion.Items.Add('Delphi 2006')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd11' then
      edtDelphiVersion.Items.Add('Delphi 2007')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd12' then
      edtDelphiVersion.Items.Add('Delphi 2009')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd14' then
      edtDelphiVersion.Items.Add('Delphi 2010')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd15' then
      edtDelphiVersion.Items.Add('Delphi XE')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd16' then
      edtDelphiVersion.Items.Add('Delphi XE2')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd17' then
      edtDelphiVersion.Items.Add('Delphi XE3')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd18' then
      edtDelphiVersion.Items.Add('Delphi XE4')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd19' then
      edtDelphiVersion.Items.Add('Delphi XE5')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd20' then
      edtDelphiVersion.Items.Add('Delphi XE6')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd21' then
      edtDelphiVersion.Items.Add('Delphi XE7')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd22' then
      edtDelphiVersion.Items.Add('Delphi XE8')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd23' then
      edtDelphiVersion.Items.Add('Delphi 10 Seattle')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd24' then
      edtDelphiVersion.Items.Add('Delphi 10.1 Berlin')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd25' then
      edtDelphiVersion.Items.Add('Delphi 10.2 Tokyo')
    else if oORMBr.Installations[iFor].VersionNumberStr = 'd26' then
      edtDelphiVersion.Items.Add('Delphi 10.3 Rio');

    // -- Evento disparado antes de iniciar a execu��o do processo.
    oORMBr.Installations[iFor].DCC32.OnBeforeExecute := BeforeExecute;

    // -- Evento para saidas de mensagens.
    oORMBr.Installations[iFor].OutputCallback := OutputCallLine;
  end;
  //
  clbDelphiVersion.Items.Text := edtDelphiVersion.Items.Text;

  if edtDelphiVersion.Items.Count > 0 then
  begin
    edtDelphiVersion.ItemIndex := 0;
    iVersion := 0;
  end;

  LerConfiguracoes;
end;

procedure TfrmPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  oORMBr.Free;
end;

procedure TfrmPrincipal.RemoverDiretoriosEPacotesAntigos;
var
  ListaPaths: TStringList;
  I: Integer;
begin
  ListaPaths := TStringList.Create;
  try
    ListaPaths.StrictDelimiter := True;
    ListaPaths.Delimiter := ';';
    with oORMBr.Installations[iVersion] do
    begin
      // remover do search path
      ListaPaths.Clear;
      ListaPaths.DelimitedText := RawLibrarySearchPath[tPlatform];
      for I := ListaPaths.Count - 1 downto 0 do
      begin
        if Pos('ORMBR', AnsiUpperCase(ListaPaths[I])) > 0 then
          ListaPaths.Delete(I);
      end;
      RawLibrarySearchPath[tPlatform] := ListaPaths.DelimitedText;
      // remover do browse path
      ListaPaths.Clear;
      ListaPaths.DelimitedText := RawLibraryBrowsingPath[tPlatform];
      for I := ListaPaths.Count - 1 downto 0 do
      begin
        if Pos('ORMBR', AnsiUpperCase(ListaPaths[I])) > 0 then
          ListaPaths.Delete(I);
      end;
      RawLibraryBrowsingPath[tPlatform] := ListaPaths.DelimitedText;
      // remover do Debug DCU path
      ListaPaths.Clear;
      ListaPaths.DelimitedText := RawDebugDCUPath[tPlatform];
      for I := ListaPaths.Count - 1 downto 0 do
      begin
        if Pos('ORMBR', AnsiUpperCase(ListaPaths[I])) > 0 then
          ListaPaths.Delete(I);
      end;
      RawDebugDCUPath[tPlatform] := ListaPaths.DelimitedText;
      // remover pacotes antigos
      for I := IdePackages.Count - 1 downto 0 do
      begin
        if Pos('ORMBR', AnsiUpperCase(IdePackages.PackageFileNames[I])) > 0 then
          IdePackages.RemovePackage(IdePackages.PackageFileNames[I]);
      end;
    end;
  finally
    ListaPaths.Free;
  end;
end;

procedure TfrmPrincipal.GetDriveLetters(AList: TStrings);
var
  vDrivesSize: Cardinal;
  vDrives: array[0..128] of Char;
  vDrive: PChar;
  vDriveType: Cardinal;
begin
  AList.BeginUpdate;
  try
    // clear the list from possible leftover from prior operations
    AList.Clear;
    vDrivesSize := GetLogicalDriveStrings(SizeOf(vDrives), vDrives);
    if vDrivesSize = 0 then
      Exit;

    vDrive := vDrives;
    while vDrive^ <> #0 do
    begin
      // adicionar somente drives fixos
      vDriveType := GetDriveType(vDrive);
      if vDriveType = DRIVE_FIXED then
        AList.Add(StrPas(vDrive));

      Inc(vDrive, SizeOf(vDrive));
    end;
  finally
	  AList.EndUpdate;
  end;
end;

function TfrmPrincipal.GetPathORMBrInc: TFileName;
begin
  Result := IncludeTrailingPathDelimiter(edtDirDestino.Text) + 'Source\ormbr.inc';
end;

// bot�o de compila��o e instala��o dos pacotes selecionados no treeview
procedure TfrmPrincipal.btnInstalarClick(Sender: TObject);
var
  iDpk: Integer;
  bRunOnly: Boolean;
  NomePacote: String;
  Cabecalho: String;
  iListaVer: Integer;

  procedure Logar(const AString: String);
  begin
    lstMsgInstalacao.Items.Add(AString);
    lstMsgInstalacao.ItemIndex := lstMsgInstalacao.Count - 1;
    Application.ProcessMessages;

    WriteToTXT(PathArquivoLog, AString);
  end;

  procedure MostrarMensagemInstalado(const aMensagem: String; const aErro: String = '');
  var
    Msg: String;
  begin

    if Trim(aErro) = EmptyStr then
    begin
      case sDestino of
        tdSystem: Msg := Format(aMensagem + ' em "%s"', [PathSystem]);
        tdDelphi: Msg := Format(aMensagem + ' em "%s"', [sPathBin]);
        tdNone:   Msg := 'Tipo de destino "nenhum" n�o aceito!';
      end;
    end
    else
    begin
      Inc(FCountErros);

      case sDestino of
        tdSystem: Msg := Format(aMensagem + ' em "%s": "%s"', [PathSystem, aErro]);
        tdDelphi: Msg := Format(aMensagem + ' em "%s": "%s"', [sPathBin, aErro]);
        tdNone:   Msg := 'Tipo de destino "nenhum" n�o aceito!';
      end;
    end;

    WriteToTXT(PathArquivoLog, '');
    Logar(Msg);
  end;

  procedure IncrementaBarraProgresso;
  begin
    pgbInstalacao.Position := pgbInstalacao.Position + 1;
    Application.ProcessMessages;
  end;

  procedure LigarDefineORMBrInc(const ADefineName: String; const Aligar: Boolean);
  var
    F: TStringList;
    I: Integer;
  begin
    F := TStringList.Create;
    try
      F.LoadFromFile(GetPathORMBrInc);
      for I := 0 to F.Count - 1 do
      begin
        if Pos(ADefineName.ToUpper, F[I].ToUpper) > 0 then
        begin
          if Aligar then
            F[I] := '{$DEFINE ' + ADefineName + '}'
          else
            F[I] := '{.$DEFINE ' + ADefineName + '}';

          Break;
        end;
      end;
      F.SaveToFile(GetPathORMBrInc);
    finally
      F.Free;
    end;
  end;

begin
//  LigarDefineORMBrInc('DRIVERRESTFUL', True);

  for iListaVer := 0 to clbDelphiVersion.Count -1 do
  begin
    // s� instala as vers�o marcadas para instalar.
    if clbDelphiVersion.Checked[iListaVer] then
    begin
      lstMsgInstalacao.Clear;
      pgbInstalacao.Position := 0;

      // seleciona a vers�o no combobox.
      edtDelphiVersion.ItemIndex := iListaVer;
      edtDelphiVersionChange(edtDelphiVersion);

      // define dados da plataforna selecionada
      SetPlatformSelected;

      // mostra dados da vers�o na tela a ser instaladas
      MostraDadosVersao();

      FCountErros := 0;

      btnInstalar.Enabled := False;
      wizPgInstalacao.EnableButton(bkNext, False);
      wizPgInstalacao.EnableButton(bkBack, False);
      wizPgInstalacao.EnableButton(TJvWizardButtonKind(bkCancel), False);
      try
        Cabecalho := 'Caminho: ' + edtDirDestino.Text + sLineBreak +
                     'Vers�o do delphi: ' + edtDelphiVersion.Text + ' (' + IntToStr(iVersion)+ ')' + sLineBreak +
                     'Plataforma: ' + edtPlatform.Text + '(' + IntToStr(Integer(tPlatform)) + ')' + sLineBreak +
                     StringOfChar('=', 80);

        // limpar o log
        lstMsgInstalacao.Clear;
        WriteToTXT(PathArquivoLog, Cabecalho, False);

        // setar barra de progresso
        pgbInstalacao.Position := 0;
        pgbInstalacao.Max := (framePacotes1.Pacotes.Count * 2) + 3;

        // *************************************************************************
        // Cria diret�rio de biblioteca da vers�o do delphi selecionada,
        // s� ser� criado se n�o existir
        // *************************************************************************
        Logar('Criando diret�rios de bibliotecas...');
        CreateDirectoryLibrarysNotExist;
        IncrementaBarraProgresso;


        // *************************************************************************
        // remover paths do delphi
        // *************************************************************************
        Logar('Removendo paths de pacotes antigos instalados...');
        RemoverDiretoriosEPacotesAntigos;
        IncrementaBarraProgresso;


        // *************************************************************************
        // Adiciona os paths dos fontes na vers�o do delphi selecionada
        // *************************************************************************
        Logar('Adicionando library paths...');
        AddLibrarySearchPath;
        IncrementaBarraProgresso;


        // *************************************************************************
        // compilar os pacotes primeiramente
        // *************************************************************************
        Logar('');
        Logar('COMPILANDO OS PACOTES...');
        for iDpk := 0 to framePacotes1.Pacotes.Count - 1 do
        begin
          NomePacote := ReplaceStr(framePacotes1.Pacotes[iDpk].Name, '_', '.');

          // Busca diret�rio do pacote
          ExtrairDiretorioPacote(NomePacote);

          if (IsDelphiPackage(NomePacote)) and (framePacotes1.Pacotes[iDpk].Checked) then
          begin
            WriteToTXT(PathArquivoLog, '');
            FPacoteAtual := sDirPackage + NomePacote;
            if oORMBr.Installations[iVersion].CompilePackage(sDirPackage + NomePacote, sDirLibrary, sDirLibrary) then
              Logar(Format('Pacote "%s" compilado.', [framePacotes1.Pacotes[iDpk].Hint]))
            else
            begin
              Inc(FCountErros);
              Logar(Format('Erro ao compilar o pacote "%s".', [framePacotes1.Pacotes[iDpk].Hint]));

              // parar no primeiro erro para evitar de compilar outros pacotes que
              // precisam do pacote que deu erro
              Break
            end;
          end;
          IncrementaBarraProgresso;
        end;


        // *************************************************************************
        // instalar os pacotes somente se n�o ocorreu erro na compila��o e plataforma for Win32
        // *************************************************************************
        if (edtPlatform.ItemIndex = 0) then
        begin
          if (FCountErros <= 0) then
          begin
            Logar('');
            Logar('INSTALANDO OS PACOTES...');

            for iDpk := 0 to framePacotes1.Pacotes.Count - 1 do
            begin
              NomePacote := ReplaceStr(framePacotes1.Pacotes[iDpk].Name, '_', '.');

              // Busca diret�rio do pacote
              ExtrairDiretorioPacote(NomePacote);

              if IsDelphiPackage(NomePacote) then
              begin
                FPacoteAtual := sDirPackage + NomePacote;
                // instalar somente os pacotes de designtime
                GetDPKFileInfo(sDirPackage + NomePacote, bRunOnly);
                if not bRunOnly then
                begin
                  // se o pacote estiver marcado instalar, sen�o desinstalar
                  if framePacotes1.Pacotes[iDpk].Checked then
                  begin
                    WriteToTXT(PathArquivoLog, '');

                    if oORMBr.Installations[iVersion].InstallPackage(sDirPackage + NomePacote, sDirLibrary, sDirLibrary) then
                      Logar(Format('Pacote "%s" instalado.', [framePacotes1.Pacotes[iDpk].Hint]))
                    else
                    begin
                      Inc(FCountErros);
                      Logar(Format('Ocorreu um erro ao instalar o pacote "%s".', [framePacotes1.Pacotes[iDpk].Hint]));

                      Break;
                    end;
                  end
                  else
                  begin
                    WriteToTXT(PathArquivoLog, '');

                    if oORMBr.Installations[iVersion].UninstallPackage(sDirPackage + NomePacote, sDirLibrary, sDirLibrary) then
                      Logar(Format('Pacote "%s" removido com sucesso...', [NomePacote]));
                  end;
                end;
              end;

              IncrementaBarraProgresso;
            end;
          end
          else
          begin
            Logar('');
            Logar('Abortando... Ocorreram erros na compila��o dos pacotes.');
          end;
        end
        else
        begin
          Logar('');
          Logar('Para a plataforma de 64 bits os pacotes s�o somente compilados.');
        end;

        if FCountErros > 0 then
        begin
          if Application.MessageBox(
            PWideChar(
              'Ocorreram erros durante o processo de instala��o, '+sLineBreak+
              'para maiores informa��es verifique o arquivo de log gerado.'+sLineBreak+sLineBreak+
              'Deseja visualizar o arquivo de log gerado?'
            ),
            'Instala��o',
            MB_ICONQUESTION + MB_YESNO
          ) = ID_YES then
          begin
            btnVisualizarLogCompilacao.Click;
            Break
          end;
        end;

        // *************************************************************************
        // n�o instalar outros requisitos se ocorreu erro anteriormente
        // *************************************************************************
        if FCountErros <= 0 then
        begin
          // *************************************************************************
          // deixar somente a pasta lib se for configurado assim
          // *************************************************************************
          if chkDeixarSomenteLIB.Checked then
          begin
            Logar('');
            Logar('INSTALANDO OUTROS REQUISITOS...');
            try
              DeixarSomenteLib;

              MostrarMensagemInstalado('Limpeza library path com sucesso');
              MostrarMensagemInstalado('Copia dos arquivos necess�rio.');
            except
              on E: Exception do
              begin
                MostrarMensagemInstalado('Ocorreu erro ao limpas os path e copiar arquivos' + sLineBreak +E.Message )
              end;
            end;
          end;
        end;
      finally
        btnInstalar.Enabled := True;
        wizPgInstalacao.EnableButton(bkBack, True);
        wizPgInstalacao.EnableButton(bkNext, FCountErros = 0);
        wizPgInstalacao.EnableButton(TJvWizardButtonKind(bkCancel), True);
      end;
    end;
  end;

  if FCountErros = 0 then
  begin
    Application.MessageBox(
      PWideChar(
        'Pacotes compilados e instalados com sucesso! '+sLineBreak+
        'Clique em "Pr�ximo" para finalizar a instala��o.'
      ),
      'Instala��o',
      MB_ICONINFORMATION + MB_OK
    );
  end;

end;

// chama a caixa de dialogo para selecionar o diret�rio de instala��o
// seria bom que a caixa fosse aquele que possui o bot�o de criar pasta
procedure TfrmPrincipal.btnSelecDirInstallClick(Sender: TObject);
var
  Dir: String;
begin
  if SelectDirectory('Selecione o diret�rio de instala��o', '', Dir, [sdNewFolder, sdNewUI, sdValidateDir]) then
    edtDirDestino.Text := Dir;
end;

// quando trocar a vers�o verificar se libera ou n�o o combo
// da plataforma de compila��o
procedure TfrmPrincipal.edtDelphiVersionChange(Sender: TObject);
begin
  iVersion := edtDelphiVersion.ItemIndex;
  sPathBin := IncludeTrailingPathDelimiter(oORMBr.Installations[iVersion].BinFolderName);
  // -- Plataforma s� habilita para Delphi XE2
  // -- Desabilita para vers�o diferente de Delphi XE2
  //edtPlatform.Enabled := oORMBr.Installations[iVersion].VersionNumber >= 9;
  //if oORMBr.Installations[iVersion].VersionNumber < 9 then
  edtPlatform.ItemIndex := 0;
end;

// abrir o endere�o do ORMBr quando clicar na propaganda
procedure TfrmPrincipal.imgPropaganda1Click(Sender: TObject);
begin
  // ir para o endere�o do ORMBr
  ShellExecute(Handle, 'open', PWideChar(lblUrl.Caption), '', '', 1);
end;

// quando clicar em alguma das urls chamar o link mostrado no caption
procedure TfrmPrincipal.URLClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PWideChar(TLabel(Sender).Caption), '', '', 1);
end;

procedure TfrmPrincipal.wizPgInicioNextButtonClick(Sender: TObject;
  var Stop: Boolean);
begin
  // Verificar se o delphi est� aberto
  {$IFNDEF DEBUG}
  if oORMBr.AnyInstanceRunning then
  begin
    Stop := True;
    Application.MessageBox(
      'Feche a IDE do delphi antes de continuar.',
      PWideChar(Application.Title),
      MB_ICONERROR + MB_OK
    );
  end;
  {$ENDIF}
end;

procedure TfrmPrincipal.wizPgInstalacaoEnterPage(Sender: TObject;
  const FromPage: TJvWizardCustomPage);
var
  iFor: Integer;
begin
  // para 64 bit somente compilar
  if tPlatform = bpWin32 then // Win32
    btnInstalar.Caption := 'Instalar'
  else // win64
    btnInstalar.Caption := 'Compilar';

  lbInfo.Clear;
  for iFor := 0 to clbDelphiVersion.Count -1 do
  begin
     // S� pega os dados da 1a vers�o selecionada, para mostrar na tela qual vai iniciar
     if clbDelphiVersion.Checked[iFor] then
     begin
        lbInfo.Items.Add('Instalar : ' + clbDelphiVersion.Items[ifor] + ' ' + edtPlatform.Text);
     end;
  end;
end;

procedure TfrmPrincipal.wizPgInstalacaoNextButtonClick(Sender: TObject;
  var Stop: Boolean);
begin
  if (lstMsgInstalacao.Count <= 0) then
  begin
    Stop := True;
    Application.MessageBox(
      'Clique no bot�o instalar antes de continuar.',
      'Erro.',
      MB_OK + MB_ICONERROR
    );
  end;

  if (FCountErros > 0) then
  begin
    Stop := True;
    Application.MessageBox(
      'Ocorreram erros durante a compila��o e instala��o dos pacotes, verifique.',
      'Erro.',
      MB_OK + MB_ICONERROR
    );
  end;
end;

procedure TfrmPrincipal.wizPgConfiguracaoNextButtonClick(Sender: TObject;
  var Stop: Boolean);
var
  iFor: Integer;
  bChk: Boolean;
  fDir: String;
begin
  bChk := False;
  for iFor := 0 to clbDelphiVersion.Count -1 do
  begin
     if clbDelphiVersion.Checked[iFor] then
        bChk := True;
  end;

  if not bChk then
  begin
    Stop := True;
    clbDelphiVersion.SetFocus;
    Application.MessageBox(
      'Para continuar escolha a vers�o do Delphi para a qual deseja instalar os Componentes.',
      'Erro.',
      MB_OK + MB_ICONERROR
    );
  end;

  // verificar se foi informado o diret�rio
  if Trim(edtDirDestino.Text) = EmptyStr then
  begin
    Stop := True;
    edtDirDestino.SetFocus;
    Application.MessageBox(
      'Diret�rio de instala��o n�o foi informado.',
      'Erro.',
      MB_OK + MB_ICONERROR
    );
  end;

  // precisa ser no mesmo diret�rio que os fontes do ORMBr esteja.
  fDir := IncludeTrailingPathDelimiter(edtDirDestino.Text);
  fDir := fDir + 'Source\ormbr.inc';
  if not FileExists(fDir) then
  begin
    Stop := True;
    edtDirDestino.SetFocus;
    Application.MessageBox(
      'Diret�rio de instala��o selecionado, n�o cont�m os fontes do ORMBr.',
      'Erro.',
      MB_OK + MB_ICONERROR
    );
  end;

  // prevenir plataforma em branco
  if Trim(edtPlatform.Text) = '' then
  begin
    Stop := True;
    edtPlatform.SetFocus;
    Application.MessageBox(
      'Plataforma de compila��o n�o foi informada.',
      'Erro.',
      MB_OK + MB_ICONERROR
    );
  end;

  // Gravar as configura��es em um .ini para utilizar depois
  GravarConfiguracoes;
end;

procedure TfrmPrincipal.btnSVNCheckoutUpdateClick(Sender: TObject);
begin
  // chamar o m�todo de update ou checkout conforme a necessidade
  if TButton(Sender).Tag > 0 then
  begin
    // criar o diret�rio onde ser� baixado o reposit�rio
    if not DirectoryExists(edtDirDestino.Text) then
    begin
      if not ForceDirectories(edtDirDestino.Text) then
      begin
        raise EDirectoryNotFoundException.Create(
          'Ocorreu o seguinte erro ao criar o diret�rio' + sLineBreak +
            SysErrorMessage(GetLastError));
      end;
    end;
  end;
end;

procedure TfrmPrincipal.btnVisualizarLogCompilacaoClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PWideChar(PathArquivoLog), '', '', 1);
end;

procedure TfrmPrincipal.clbDelphiVersionClick(Sender: TObject);
begin
  if MatchText(oORMBr.Installations[clbDelphiVersion.ItemIndex].VersionNumberStr, ['d3','d4','d5','d6','d7','d9','d10','d11','d12','d13']) then
  begin
    Application.MessageBox(
      'Vers�o do delphi n�o suportada pelo ORMBr Components.',
      'Erro.',
      MB_OK + MB_ICONERROR
    );
  end;
end;

procedure TfrmPrincipal.wizPgObterFontesNextButtonClick(Sender: TObject;
  var Stop: Boolean);
var
  I: Integer;
  NomePacote: String;
begin
  GravarConfiguracoes;

  // verificar se os pacotes existem antes de seguir para o pr�ximo paso
  for I := 0 to framePacotes1.Pacotes.Count - 1 do
  begin
    if framePacotes1.Pacotes[I].Checked then
    begin
      sDirRoot   := IncludeTrailingPathDelimiter(edtDirDestino.Text);
      NomePacote := framePacotes1.Pacotes[I].Hint;

      // Busca diret�rio do pacote
      ExtrairDiretorioPacote(NomePacote);
      if Trim(sDirPackage) = '' then
        raise Exception.Create('N�o foi poss�vel retornar o diret�rio do pacote : ' + NomePacote);

      if IsDelphiPackage(NomePacote) then
      begin
        if not FileExists(IncludeTrailingPathDelimiter(sDirPackage) + NomePacote) then
        begin
          Stop := True;
          Application.MessageBox(PWideChar(Format(
            'Pacote "%s" n�o encontrado, efetue novamente o download do reposit�rio', [NomePacote])),
            'Erro.',
            MB_ICONERROR + MB_OK
          );
          Break;
        end;
      end;
    end;
  end;
end;

procedure TfrmPrincipal.wizPrincipalCancelButtonClick(Sender: TObject);
begin
  if Application.MessageBox(
    'Deseja realmente cancelar a instala��o?',
    'Fechar',
    MB_ICONQUESTION + MB_YESNO
  ) = ID_YES then
  begin
    Self.Close;
  end;
end;

procedure TfrmPrincipal.wizPrincipalFinishButtonClick(Sender: TObject);
begin
  Self.Close;
end;

end.
