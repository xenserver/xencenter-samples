@echo off

echo Building resources...

if exist .\_build  rd .\_build /s /q

set PLUGIN_DIR=.\_build\Plugins\Citrix\NetAppWebUI\
md %PLUGIN_DIR%

copy *.xml %PLUGIN_DIR%

echo Creating installer...

powershell -ExecutionPolicy ByPass -File ..\PluginInstaller\Create-PluginInstaller.ps1 -out .\_build\NetAppWebUI.msi -title "XenCenter NetAppWebUI Plugin" -description "Sample plugin for XenCenter" -manufacturer "Citrix" -upgrade_code $([System.Guid]::NewGuid().ToString())

del .\_build\*.w* /q
echo Done