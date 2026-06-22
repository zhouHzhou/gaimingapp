[Setup]
AppName=批量重命名
AppVersion=1.0
AppPublisher=BatchRenamer
DefaultDirName={autopf}\批量重命名
DefaultGroupName=批量重命名
UninstallDisplayIcon={app}\批量重命名.exe
OutputDir=installer_output
OutputBaseFilename=批量重命名_安装包
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=admin
SetupIconFile=

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加选项:"; Flags: unchecked

[Files]
Source: "dist\批量重命名.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\批量重命名"; Filename: "{app}\批量重命名.exe"
Name: "{group}\卸载 批量重命名"; Filename: "{uninstallexe}"
Name: "{autodesktop}\批量重命名"; Filename: "{app}\批量重命名.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\批量重命名.exe"; Description: "启动 批量重命名"; Flags: nowait postinstall skipifsilent
