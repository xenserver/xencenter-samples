Echo Run this make file from a Visual Sutdio Command Prompt
Echo PowerShell version 2.0 or higher is required to run this
Echo WiX 2.0 or higher is assumed installed to compile the installer
Echo Building resources ..
Del .\plugins\xenserver.org\NetAppWebUI\*.* /q
Del .\plugins\*.* /q
cd .\output
Del *.* /q
cd ..
copy *.xml .\plugins\xenserver.org\NetAppWebUI

Echo creating installer
powershell -ExecutionPolicy ByPass -File ..\PluginInstaller\Create-PluginInstaller.ps1 -out .\output\NetAppWebUI.msi -title "XenCenter NetAppWebUI Plugin" -description "Sample plugin for XenCenter" -manufacturer "XenServer.org" -upgrade_code $([System.Guid]::NewGuid().ToString())

Del .\output\*.w* /q

Echo Done.