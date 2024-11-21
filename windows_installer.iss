#define MyAppName "LedgerPro"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "LedgerPro"
#define MyAppExeName "ledgerpro.exe"

[Setup]
AppId={{2EC62F9B-8E61-4C24-A4B5-7A8F43F9B2A1}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=build\installer
OutputBaseFilename=LedgerPro-Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#MyAppExeName}
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Exclude database files with the excludes parameter
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs; Excludes: "*.db,*.db-journal"
Source: "windows\dlls\sqlite3.dll"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
Type: filesandordirs; Name: "{localappdata}\{#MyAppName}"
Type: filesandordirs; Name: "{userappdata}\{#MyAppName}"
Type: files; Name: "{app}\.dart_tool\*"
Type: dirifempty; Name: "{app}\.dart_tool"

[Code]
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  LocalAppData: String;
  UserAppData: String;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    LocalAppData := ExpandConstant('{localappdata}\{#MyAppName}');
    UserAppData := ExpandConstant('{userappdata}\{#MyAppName}');
    
    // Delete application data directories if they exist
    if DirExists(LocalAppData) then
      DelTree(LocalAppData, True, True, True);
    if DirExists(UserAppData) then
      DelTree(UserAppData, True, True, True);
      
    // Clean up any remaining .dart_tool directory
    if DirExists(ExpandConstant('{app}\.dart_tool')) then
      DelTree(ExpandConstant('{app}\.dart_tool'), True, True, True);
  end;
end;
