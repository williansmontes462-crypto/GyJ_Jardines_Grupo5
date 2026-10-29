@echo off
setlocal
where flutter >nul 2>nul
if errorlevel 1 (
  echo No se encontro Flutter en PATH.
  echo Instala Flutter y la extension Flutter de VS Code y vuelve a ejecutar este archivo.
  pause
  exit /b 1
)
flutter create --platforms=android,web .
if errorlevel 1 (
  echo Hubo un problema al generar las carpetas de plataforma.
  pause
  exit /b 1
)
flutter pub get
if errorlevel 1 (
  echo Hubo un problema al descargar las dependencias.
  pause
  exit /b 1
)
echo Proyecto preparado. Ejecuta: flutter run
pause
