[Setup]
AppName=AnimeGo
AppVersion=1.0.0
AppPublisher=AnimeGo
DefaultDirName={autopf}\AnimeGo
DefaultGroupName=AnimeGo
OutputDir=D:\AnimeAPP\installer_output
OutputBaseFilename=AnimeGo_Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\anime_app.exe

[Files]
Source: "D:\AnimeAPP\build\windows\x64\runner\Release\anime_app.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\AnimeAPP\build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\AnimeAPP\build\windows\x64\runner\Release\d3dcompiler_47.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\AnimeAPP\build\windows\x64\runner\Release\libEGL.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\AnimeAPP\build\windows\x64\runner\Release\libGLESv2.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\AnimeAPP\build\windows\x64\runner\Release\libc++.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\AnimeAPP\build\windows\x64\runner\Release\libmpv-2.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\AnimeAPP\build\windows\x64\runner\Release\vk_swiftshader.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\AnimeAPP\build\windows\x64\runner\Release\vulkan-1.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\AnimeAPP\build\windows\x64\runner\Release\zlib.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\AnimeAPP\build\windows\x64\runner\Release\media_kit_libs_windows_video_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\AnimeAPP\build\windows\x64\runner\Release\media_kit_video_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\AnimeAPP\build\windows\x64\runner\Release\volume_controller_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "D:\AnimeAPP\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\AnimeGo"; Filename: "{app}\anime_app.exe"
Name: "{group}\卸载 AnimeGo"; Filename: "{uninstallexe}"
Name: "{commondesktop}\AnimeGo"; Filename: "{app}\anime_app.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加图标:"

[Run]
Filename: "{app}\anime_app.exe"; Description: "启动 AnimeGo"; Flags: nowait postinstall skipifsilent
