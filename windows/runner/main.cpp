#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <algorithm>
#include <string>
#include <vector>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  const auto initial_arguments = GetCommandLineArguments();
  constexpr char kSoftwareRendering[] = "--enable-software-rendering";
  const bool software_rendering_requested =
      std::find(initial_arguments.begin(), initial_arguments.end(),
                kSoftwareRendering) != initial_arguments.end();

  // Engine switches must be present in the process command line before the
  // Flutter engine is created. Passing this value as a Dart entrypoint
  // argument is too late and leaves ANGLE active. Relaunch once with the
  // switch on the real Windows command line so DWM receives a stable surface.
  if (!software_rendering_requested) {
    wchar_t executable[MAX_PATH];
    const DWORD length = ::GetModuleFileNameW(nullptr, executable, MAX_PATH);
    if (length == 0 || length == MAX_PATH) {
      return EXIT_FAILURE;
    }

    std::wstring relaunched = L"\"" + std::wstring(executable, length) +
                              L"\" --enable-software-rendering";
    if (command_line != nullptr && command_line[0] != L'\0') {
      relaunched += L" ";
      relaunched += command_line;
    }

    std::vector<wchar_t> mutable_command(relaunched.begin(), relaunched.end());
    mutable_command.push_back(L'\0');
    STARTUPINFOW startup_info = {};
    startup_info.cb = sizeof(startup_info);
    PROCESS_INFORMATION process_info = {};
    if (!::CreateProcessW(nullptr, mutable_command.data(), nullptr, nullptr,
                          FALSE, 0, nullptr, nullptr, &startup_info,
                          &process_info)) {
      return EXIT_FAILURE;
    }
    ::CloseHandle(process_info.hThread);
    ::CloseHandle(process_info.hProcess);
    return EXIT_SUCCESS;
  }

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
  Win32Window::Point origin(40, 40);
  Win32Window::Size size(1440, 900);
  if (!window.Create(L"FLCAD Reverse AI — Engineering Intelligence Platform", origin, size)) {
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
