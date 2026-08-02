; ExaPDF 윈도우 설치 프로그램 (Inno Setup 6)
;
; 만들기:
;   flutter build windows --release --dart-define-from-file=.env.json
;   "%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe" installer\exapdf.iss
;
; 결과물: installer\out\ExaPDF-설치-{버전}.exe
;
; 왜 서명하지 않는가 — 이 프로젝트는 고정비 0 이 원칙이고(CLAUDE.md §1),
; 코드 서명 인증서는 해마다 돈이 든다. 대신 SmartScreen 경고가 왜 뜨는지
; 배포 페이지에 적어 둔다. 나중에 서명을 붙이면 이 주석과 함께 지운다.

#define AppName "ExaPDF"
#define AppVersion "1.0.0"
#define Publisher "EXANSYS Co., Ltd."
#define AppURL "https://exapdf.exansys.net"
#define ExeName "exapdf.exe"
#define SrcDir "..\app\build\windows\x64\runner\Release"

[Setup]
AppId={{7C4E0B62-2F51-4E1B-9F0B-9C1D5A0E3A11}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#Publisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
VersionInfoVersion={#AppVersion}

; 관리자 권한을 요구하지 않는다. 사용자 폴더에 깔면 대부분의 회사 PC 에서도
; 그냥 설치된다 — 권한을 물으면 거기서 절반이 그만둔다
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
AllowNoIcons=yes
; **설치 폴더를 사용자가 고르게 한다.** 다른 드라이브(D:\ 등)도 된다 —
; SSD 가 작은 PC 에서 큰 프로그램을 C 에 강제하면 그것만으로 안 쓰게 된다
DisableDirPage=no
UsePreviousAppDir=yes

OutputDir=out
OutputBaseFilename=ExaPDF-설치-{#AppVersion}
SetupIconFile=..\app\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#ExeName}
UninstallDisplayName={#AppName}

Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; 개인정보처리방침을 설치 과정에 **반드시 거치게** 넣는다.
; 읽지 않고 넘길 수 있는 안내가 아니라, 동의해야 다음으로 간다
LicenseFile=privacy-ko.txt

[Languages]
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"

[CustomMessages]
korean.PrivacyCaption=개인정보처리방침
korean.PrivacyDesc=계속하려면 아래 내용을 읽고 동의해 주세요.
korean.AgreeText=위 개인정보처리방침에 동의합니다
korean.LaunchApp={#AppName} 실행

[Tasks]
Name: "desktopicon"; Description: "바탕화면에 바로가기 만들기"; GroupDescription: "추가 작업:"

[Files]
; 실행 파일과 런타임 DLL, 에셋을 통째로. 빠뜨리면 실행 즉시 죽는다
Source: "{#SrcDir}\{#ExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SrcDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SrcDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; 설치 후에도 언제든 읽을 수 있게 문서를 함께 깐다
Source: "privacy-ko.txt"; DestDir: "{app}"; DestName: "개인정보처리방침.txt"; Flags: ignoreversion
Source: "..\docs\MANUAL.md"; DestDir: "{app}"; DestName: "사용설명서.md"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#ExeName}"
Name: "{group}\{cm:PrivacyCaption}"; Filename: "{app}\개인정보처리방침.txt"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#ExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#ExeName}"; Description: "{cm:LaunchApp}"; Flags: nowait postinstall skipifsilent

[Code]
{ 라이선스 창을 개인정보처리방침 동의로 쓴다.
  Inno 기본 라이선스 페이지는 "동의함/동의 안 함" 라디오가 이미 있어
  동의 없이는 다음으로 못 간다. 문구만 우리 말로 바꾼다. }
procedure InitializeWizard();
begin
  WizardForm.LicenseLabel1.Caption :=
    '설치를 계속하려면 아래 개인정보처리방침을 읽고 동의해 주세요.' + #13#10 +
    'ExaPDF 는 회원가입이 없고, 여러분의 책과 기록을 밖으로 보내지 않습니다.';
  WizardForm.LicenseAcceptedRadio.Caption := ExpandConstant('{cm:AgreeText}');
  WizardForm.LicenseNotAcceptedRadio.Caption := '동의하지 않습니다 (설치를 끝냅니다)';
end;

function InitializeUninstall(): Boolean;
begin
  Result := True;
end;

{ 지울 때 자료까지 지울지 물어본 뒤에만 지운다.
  UninstallDelete 섹션으로 두면 말없이 사라진다. 칠해 둔 것과 읽던 자리는
  다시 만들 수 없는 것이라, 기본값이 "남긴다" 여야 한다. }
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  DataDir: String;
begin
  if CurUninstallStep = usUninstall then
  begin
    DataDir := ExpandConstant('{localappdata}\{#Publisher}\{#AppName}');
    if DirExists(DataDir) then
      if MsgBox('서재 목록·읽던 자리·칠한 것도 함께 지울까요?' + #13#10#13#10 +
                '아니요를 고르면 자료가 남아, 다시 설치했을 때 그대로 이어집니다.' + #13#10 +
                '(원본 PDF 파일은 어느 쪽이든 지우지 않습니다)',
                mbConfirmation, MB_YESNO) = IDYES then
        DelTree(DataDir, True, True, True);
  end;
end;
