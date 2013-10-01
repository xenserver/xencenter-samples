Echo Run this make file from a Visual Sutdio Command Prompt
Echo PowerShell version 2.0 or higher is required to run this
Echo WiX 2.0 or higher is assumed installed to compile the installer
Echo Building resources ..
Del .\plugins\xenserver.org\HelloWorld\*.* /q
Del .\plugins\xenserver.org\HelloWorld\images\*.* /q
Del .\plugins\*.* /q
cd .\output
Del *.* /q
ResGen ../HelloWorld.resx HelloWorld.resources
al /t:lib /embed:HelloWorld.resources /culture:0x007F /out:HelloWorld.resoures.dll
cd ..
copy *.xml .\plugins\xenserver.org\HelloWorld
copy *.ps1 .\plugins\xenserver.org\HelloWorld
copy .\images\*.png .\plugins\xenserver.org\HelloWorld\images
copy .\output\*.dll .\plugins\xenserver.org\HelloWorld


Echo creating installer
powershell -ExecutionPolicy ByPass -File ..\PluginInstaller\Create-PluginInstaller.ps1 -out .\output\HelloWorld.msi -title "XenCenter HelloWorld Plugin" -description "Sample plugin for XenCenter" -manufacturer "XenServer.org" -upgrade_code $([System.Guid]::NewGuid().ToString())

Del .\output\*.r* /q
Del .\output\*.w* /q

Echo Done.