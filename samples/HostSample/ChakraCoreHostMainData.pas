(*

MIT License

Copyright (c) 2018 Ondrej Kelle

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*)

unit ChakraCoreHostMainData;

interface

{$include common.inc}

uses
{$ifdef LINUX}
{$ifdef FPC}
  cwstring,
{$endif}
{$endif}
  SysUtils, Classes,
{$ifdef HAS_WIDESTRUTILS}
  WideStrUtils,
{$endif}
  Compat, ChakraCoreUtils, ChakraCoreClasses, Console;

type
  TDataModuleMain = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FBaseDir: UnicodeString;
    FConsole: TConsole;
    FContext: TChakraCoreContext;
    FRuntime: TChakraCoreRuntime;

    procedure ContextLoadModule(Sender: TObject; Module: TChakraModule);
  public
    procedure Execute(const ScriptFileNames: array of UnicodeString);

    property Console: TConsole read FConsole;
  end;

implementation

{$R *.dfm}

function LoadFile(const FileName: UnicodeString): UnicodeString;
var
  FileStream: TFileStream;
  S: UTF8String;
begin
  Result := '';

  FileStream := TFileStream.Create(FileName, fmOpenRead);
  try
    if FileStream.Size = 0 then
      Exit;

    SetLength(S, FileStream.Size);
    FileStream.Read(S[1], FileStream.Size);

    Result := UTF8ToString(S);
  finally
    FileStream.Free;
  end;
end;

procedure TDataModuleMain.ContextLoadModule(Sender: TObject; Module: TChakraModule);
var
  ModuleFileName: UnicodeString;
begin
  ModuleFileName := IncludeTrailingPathDelimiter(FBaseDir) +
    ChangeFileExt(JsStringToUnicodeString(Module.Specifier), '.js');
  if FileExists(ModuleFileName) then
    Module.Parse(LoadFile(ModuleFileName));
end;

procedure TDataModuleMain.DataModuleCreate(Sender: TObject);
begin
  try
    FRuntime := TChakraCoreRuntime.Create([ccroEnableExperimentalFeatures, ccroDispatchSetExceptionsToDebugger]);
    FContext := TChakraCoreContext.Create(FRuntime);
    FContext.OnLoadModule := ContextLoadModule;
    FContext.Activate;

    TConsole.Project;

    FConsole := TConsole.Create;
    JsSetProperty(FContext.Global, 'console', FConsole.Instance);
  except
    FConsole := nil;
    FreeAndNil(FContext);
    FreeAndNil(FRuntime);
    raise;
  end;
end;

procedure TDataModuleMain.DataModuleDestroy(Sender: TObject);
begin
  FreeAndNil(FConsole);
  FConsole := nil;
  FreeAndNil(FContext);
  FreeAndNil(FRuntime);
end;

procedure TDataModuleMain.Execute(const ScriptFileNames: array of UnicodeString);
var
  I: Integer;
begin
  for I := Low(ScriptFileNames) to High(ScriptFileNames) do
  begin
    FBaseDir := ExtractFilePath(ScriptFileNames[I]);
    FContext.RunScript(LoadFile(ScriptFilenames[I]), UnicodeString(ExtractFileName(ScriptFileNames[I])));
  end;
end;

end.
