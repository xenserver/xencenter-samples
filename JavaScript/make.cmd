@echo off

echo Building resources...

if exist .\_build  rd .\_build /s /q

set PLUGIN_DIR=.\_build\Plugins\Citrix\MessageBoard\
md %PLUGIN_DIR%

ResGen MessageBoard.resx MessageBoard.resources
al /t:lib /embed:MessageBoard.resources /out:MessageBoard.resources.dll
move MessageBoard.resources.dll %PLUGIN_DIR%
del MessageBoard.resources

copy *.css  %PLUGIN_DIR%
copy *.html %PLUGIN_DIR%
copy *.js   %PLUGIN_DIR%
copy *.xml  %PLUGIN_DIR%
copy .\images\*.png %PLUGIN_DIR%

echo Creating installer...

powershell -ExecutionPolicy ByPass -File ..\PluginInstaller\Create-PluginInstaller.ps1 -out .\_build\MessageBoard.msi -title "XenCenter MessageBoard Plugin" -description "Sample plugin for XenCenter" -manufacturer "Citrix" -upgrade_code $([System.Guid]::NewGuid().ToString())

del .\_build\*.w* /q
echo Done