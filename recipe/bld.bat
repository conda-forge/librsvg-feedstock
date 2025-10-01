setlocal EnableDelayedExpansion
@echo on

FOR /F "delims=" %%i IN ('cygpath.exe -m "%LIBRARY_PREFIX%"') DO set "LIBRARY_PREFIX_M=%%i"

:: set pkg-config path so that host deps can be found
set "PKG_CONFIG_PATH=%LIBRARY_LIB%\pkgconfig;%LIBRARY_PREFIX%\share\pkgconfig"

:: set XDG_DATA_DIRS to find gir files
set "XDG_DATA_DIRS=%LIBRARY_PREFIX%\share"

:: :: add include dirs to search path
:: set "INCLUDE=%INCLUDE%;%LIBRARY_INC%\cairo;%LIBRARY_INC%\gdk-pixbuf-2.0"
::
:: :: build options
:: :: (override rustup command so that the conda-forge rust installation is used)
:: :: (add libiconv for linking against because glib needs its symbols)
:: :: (abuse LIBINTL_LIB to add libs that are needed for linking RSVG tools)
:: :: (override BINDIR to ensure the gobject-introspection tools are found)
:: set ^"LIBRSVG_OPTIONS=^
::   CFG=release ^
::   PREFIX="%LIBRARY_PREFIX%" ^
::   BINDIR="%BUILD_PREFIX%\Library\bin" ^
::   INTROSPECTION=1 ^
::   RUSTUP=echo ^
::   PYTHON="%BUILD_PREFIX%\python.exe" ^
::   TOOLCHAIN_TYPE=stable ^
::   LIBINTL_LIB="intl.lib iconv.lib advapi32.lib bcrypt.lib ws2_32.lib userenv.lib ntdll.lib" ^
::   CARGO_CMD="cargo --locked build --release $(MANIFEST_PATH_FLAG) $(CARGO_TARGET_DIR_FLAG)" ^
::  ^"

mkdir forgebuild
cd forgebuild

meson setup ^
  --buildtype=release ^
  --prefix=%LIBRARY_PREFIX% ^
  --backend=ninja ^
  -Dintrospection=enabled ^
  -Dpixbuf=enabled ^
  -Dpixbuf-loader=enabled ^
  -Dcfextragirdir=%LIBRARY_PREFIX%\share\gir-1.0 ^
  ..
if errorlevel 1 exit 1

ninja
if errorlevel 1 exit 1

ninja install
if errorlevel 1 exit 1

:: Copy libraries to be named consistently with the Autotools builds.
:: This way people can migrate to the new names, but we don't break
:: packages that still depend on the old ones.
copy %LIBRARY_BIN%\rsvg-2-2.dll %LIBRARY_BIN%\rsvg-2.0-vs%VS_MAJOR%.dll
if errorlevel 1 exit 1
copy %LIBRARY_LIB%\rsvg-2.lib %LIBRARY_LIB%\rsvg-2.0.lib
if errorlevel 1 exit 1

:: This may not be necessary? Haven't checked what gdk-pixbuf looks
:: for on Windows.
move %LIBRARY_LIB%\gdk-pixbuf-2.0\2.10.0\loaders\pixbufloader_svg.dll %LIBRARY_LIB%\gdk-pixbuf-2.0\2.10.0\loaders\libpixbufloader_svg.dll
if errorlevel 1 exit 1

rmdir /s /q %LIBRARY_PREFIX%\share\doc
