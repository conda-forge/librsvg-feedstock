setlocal EnableDelayedExpansion
@echo on

:: take care we don't use an accidential released rust config
:: and later fall over it ...
del /q %BUILD_PREFIX%\.cargo.win\config
set MKDIR_P="mkdir"

cd "win32"

set PATH=%BUILD_PREFIX%\bin;%PATH%

:: set pkg-config path so that host deps can be found
set "PKG_CONFIG_PATH=%LIBRARY_LIB%\pkgconfig;%LIBRARY_PREFIX%\share\pkgconfig;%BUILD_PREFIX%\Library\lib\pkgconfig"

:: set XDG_DATA_DIRS to find gir files
set "XDG_DATA_DIRS=%XDG_DATA_DIRS%;%LIBRARY_PREFIX%\share"

:: add include dirs to search path
set "INCLUDE=%INCLUDE%;%LIBRARY_INC%\cairo;%LIBRARY_INC%\gdk-pixbuf-2.0"

findstr /m "C:/ci_310/glib_1642686432177/_h_env/Library/lib/z.lib" "%LIBRARY_LIB%\pkgconfig\gio-2.0.pc"
 if %errorlevel%==0 (
    :: our current glib gio-2.0.pc has zlib dependency set as an absolute path. 
    powershell -Command "(gc %LIBRARY_LIB%\pkgconfig\gio-2.0.pc) -replace 'Requires:', 'Requires: zlib,' | Out-File -encoding ASCII %LIBRARY_LIB%\pkgconfig\gio-2.0.pc"
    powershell -Command "(gc %LIBRARY_LIB%\pkgconfig\gio-2.0.pc) -replace 'C:/ci_310/glib_1642686432177/_h_env/Library/lib/z.lib', '' | Out-File -encoding ASCII %LIBRARY_LIB%\pkgconfig\gio-2.0.pc"
)

IF NOT EXIST "%LIBRARY_PREFIX%\lib\png16.lib" (
  :: the build looks for png16.lib
  copy "%LIBRARY_PREFIX%"\lib\libpng16.lib "%LIBRARY_PREFIX%\lib\png16.lib"
)

:: build options
:: (override rustup command so that the conda-forge rust installation is used)
:: (add libiconv for linking against because glib needs its symbols)
:: (abuse LIBINTL_LIB to add libs that are needed for linking RSVG tools)
:: (override BINDIR to ensure the gobject-introspection tools are found)
:: (introspection disabled: enable by setting INTROSPECTION=1 )
set ^"LIBRSVG_OPTIONS=^
  CFG=release ^
  PREFIX="%LIBRARY_PREFIX%" ^
  BINDIR="%BUILD_PREFIX%\Library\bin" ^
  LIBDIR="%LIBRARY_PREFIX%\lib" ^
  INTROSPECTION=1 ^
  RUSTUP=echo ^
  LIBINTL_LIB="intl.lib iconv.lib advapi32.lib" ^
 ^"

:: configure files
:: (use cmake just because it's convenient for replacing @VAR@ in files
cmake -DPACKAGE_VERSION=%PKG_VERSION% -P "%RECIPE_DIR%\win_configure_files.cmake"
if errorlevel 1 exit 1

nmake /F Makefile.vc !LIBRSVG_OPTIONS!
if errorlevel 1 exit 1

nmake /F Makefile.vc install !LIBRSVG_OPTIONS!
if errorlevel 1 exit 1

:: don't include debug symbols
del %LIBRARY_BIN%\rsvg-*.pdb
if errorlevel 1 exit 1
del %LIBRARY_LIB%\gdk-pixbuf-2.0\2.10.0\loaders\libpixbufloader-svg.pdb
if errorlevel 1 exit 1
