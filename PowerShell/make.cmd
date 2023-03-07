@echo off

echo Building resources...

if exist .\_build  rd .\_build /s /q

set PLUGIN_DIR=.\_build\Plugins\XenServer\HelloWorld\
md %PLUGIN_DIR%

ResGen HelloWorld.resx HelloWorld.resources
al /t:lib /embed:HelloWorld.resources /out:HelloWorld.resources.dll
move HelloWorld.resources.dll %PLUGIN_DIR%
del HelloWorld.resources

copy *.xml %PLUGIN_DIR%
copy *.ps1 %PLUGIN_DIR%
copy .\images\*.png %PLUGIN_DIR%

echo Creating installer
powershell -ExecutionPolicy ByPass -File ..\PluginInstaller\Create-PluginInstaller.ps1 -out .\_build\HelloWorld.msi -title "XenCenter HelloWorld Plugin" -description "Sample plugin for XenCenter" -manufacturer "XenServer" -upgrade_code $([System.Guid]::NewGuid().ToString())

del .\_build\*.w* /q
echo Done