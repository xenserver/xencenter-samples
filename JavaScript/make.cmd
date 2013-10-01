Echo Run this make file from a Visual Sutdio Command Prompt
Echo PowerShell version 2.0 or higher is required to run this
Echo WiX 2.0 or higher is assumed installed to compile the installer
Echo Building resources ..
Del .\plugins\xenserver.org\MessageBoard\*.* /q
Del .\plugins\xenserver.org\MessageBoard\images\*.* /q
Del .\plugins\*.* /q
cd .\output
Del *.* /q
ResGen ../MessageBoard.resx MessageBoard.resources
al /t:lib /embed:MessageBoard.resources /culture:0x007F /out:MessageBoard.resoures.dll
cd ..
copy *.css .\plugins\xenserver.org\MessageBoard
copy *.html .\plugins\xenserver.org\MessageBoard
copy *.css .\plugins\xenserver.org\MessageBoard
copy *.gif .\plugins\xenserver.org\MessageBoard
copy *.js .\plugins\xenserver.org\MessageBoard
copy *.xml .\plugins\xenserver.org\MessageBoard
copy .\images\*.png .\plugins\xenserver.org\MessageBoard\images
copy .\output\*.dll .\plugins\xenserver.org\MessageBoard


Echo creating installer
powershell -ExecutionPolicy ByPass -File ..\PluginInstaller\Create-PluginInstaller.ps1 -out .\output\MessageBoard.msi -title "XenCenter MessageBoard Plugin" -description "Sample plugin for XenCenter" -manufacturer "XenServer.org" -upgrade_code $([System.Guid]::NewGuid().ToString())

Del .\output\*.r* /q
Del .\output\*.w* /q

Echo Done.