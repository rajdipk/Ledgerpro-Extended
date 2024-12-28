#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// Register URL protocol handler
void RegisterURLProtocol() {
  HKEY hKey;
  wchar_t exePath[MAX_PATH];
  GetModuleFileNameW(NULL, exePath, MAX_PATH);

  // Create protocol key
  if (RegCreateKeyExW(HKEY_CURRENT_USER, L"Software\\Classes\\ledgerpro", 0, NULL, 0,
                      KEY_WRITE, NULL, &hKey, NULL) == ERROR_SUCCESS) {
    const wchar_t* protocolDesc = L"LedgerPro URL Protocol";
    DWORD descSize = static_cast<DWORD>((wcslen(protocolDesc) + 1) * sizeof(wchar_t));
    RegSetValueExW(hKey, NULL, 0, REG_SZ, reinterpret_cast<const BYTE*>(protocolDesc),
                   descSize);
    RegSetValueExW(hKey, L"URL Protocol", 0, REG_SZ, reinterpret_cast<const BYTE*>(L""),
                   sizeof(wchar_t));
    RegCloseKey(hKey);

    // Create command key
    if (RegCreateKeyExW(HKEY_CURRENT_USER,
                        L"Software\\Classes\\ledgerpro\\shell\\open\\command", 0,
                        NULL, 0, KEY_WRITE, NULL, &hKey, NULL) == ERROR_SUCCESS) {
      std::wstring commandLine = std::wstring(exePath) + L" %1";
      DWORD cmdSize = static_cast<DWORD>((commandLine.length() + 1) * sizeof(wchar_t));
      RegSetValueExW(hKey, NULL, 0, REG_SZ, reinterpret_cast<const BYTE*>(commandLine.c_str()),
                     cmdSize);
      RegCloseKey(hKey);
    }
  }
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Register URL protocol handler
  RegisterURLProtocol();

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"ledgerpro", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
