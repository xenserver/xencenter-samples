#Load DLLs
[reflection.assembly]::loadwithpartialname('system.windows.forms')
$SelectedObjectNames=@();
$XenCenterNodeSelected = 0;
#the object info array contains hashmaps, each of which represent a parameter set and describe a target in the XenCenter resource list
foreach($parameterSet in $ObjInfoArray)
{
	if ($parameterSet["class"] -eq "blank")
	{
		#When the XenCenter node is selected a parameter set is created for each of your connected servers with the class and objUuid keys marked as blank
		if ($XenCenterNodeSelected)
		{
			continue
		}
		$XenCenterNodeSelected = 1;
		$SelectedObjectNames += "XenCenter"
	}
	elseif ($parameterSet["sessionRef"] -eq "null")
	{
		#When a disconnected server is selected there is no session information, we get null for everything except class
		$SelectedObjectNames += "a disconnected server"
	}
	else
	{
		Connect-XenServer -url $parameterSet["url"] -opaqueref $parameterSet["sessionRef"]
		#Use $class to determine which server objects to get
		#-properties allows us to filter the results to just include the selected object
		$exp = "Get-XenServer:{0} -properties @{{uuid='{1}'}}" -f $parameterSet["class"], $parameterSet["objUuid"]
		$obj = Invoke-Expression $exp
		$SelectedObjectNames += $obj.name_label;
	}
}
#now a bit of pretty string formatting
$NameString = "Hello from {0}" -f $SelectedObjectNames[0];
if ($SelectedObjectNames.length -gt 1)
{
	#we are aiming for "name_1, name_2, name_3...name_n-1 and name_n"
	for ($i=1; $i -lt $SelectedObjectNames.length - 1; $i++)
	{
		$NameString += ", {0}" -f $SelectedObjectNames[$i]
	}
	$NameString += " and {0}" -f $SelectedObjectNames[$SelectedObjectNames.length - 1]
}
#show an alert dialog with the text
[system.Windows.Forms.MessageBox]::show($NameString, "Hello World")