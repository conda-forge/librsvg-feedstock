@echo on
gdk-pixbuf-query-loaders > test-loaders.cache
if errorlevel 1 exit /b 1
set "GDK_PIXBUF_MODULE_FILE=%CD%\test-loaders.cache"
rsvg-convert --output converted.png test.svg
if errorlevel 1 exit /b 1
cmake -S . -B consumer-build -G Ninja -DCMAKE_BUILD_TYPE=Release
if errorlevel 1 exit /b 1
cmake --build consumer-build
if errorlevel 1 exit /b 1
consumer-build\rsvg-consumer.exe
if errorlevel 1 exit /b 1
