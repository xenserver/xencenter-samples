$(document).ready(RefreshPage);

function RefreshPage()
{
	// hide the error div and show the main content div
	$("#content").css({"display" : ""});
	$("#errorContent").css({"display" : "none"});
	$("#errorMessage").html("");
	RefreshMessagesAndStatus();
	RefreshDescription();
	RefreshTags();
}

// LOCAL VARIABLES SECTION
// Each message is a post on the message board and is stored on the other config map of the server object (a string, string map) under the key defined below.
// The value of this entry is a json encoding of an array of these messages, and each message has its string fields escaped so as not to break the xmlrpc.
// These fields are only escaped when they are put on the server, and are unescaped when saved to the local array (Messages).
var StatusString;
var StatusStringOtherConfigKey = "XCServerMessagesPluginStatus";
var Messages = new Array();
var MessageOtherConfigKey = "XCServerMessagesPlugin";

function ClearAll()
{
	if (confirm("This will clear your status and all of your messages. Do you wish to continue?"))
	{
		Messages.length = 0;
		StatusString = "";
		SaveDataToServer();
	}
}

// MESSAGE OBJECT SECTION
// We force uniqueness on the titles and use it as a key for deleting and editing
function Message(t, n, d, b)
{
	this.title = t;
	this.name = n;
	this.date = d;
	this.body = b;
}

function MessageToJson(message)
{
	return '{"title" : "' + escape(message.title) + '", "name" : "' + escape(message.name) + '", "date" : "' + escape(message.date) + '", "body" : "' + escape(message.body) + '"}';
}

function DrawMessage(Title, Name, Date, Body)
{
	var newThread = '<div class="messageBox" id="message' + Title + '">'
		+ '<div class="messageTitleBar">'
		+ 	'<span class="messageTitle">' + Title + '</span>'
		+ 	'<span class="messageAuthor">' + Name + '</span>'
		+ 	'<span class="messageDate">' + Date + '</span>'
		+ '</div>'
		+ '<div class="messageBody">' + Body + '</div>'
		+ '<div class="messageFooter">'
		+	'<span class="linkLabel" onClick="EditMessage(\'' + Title + '\')">Edit</span>'
		+	'<span class="linkLabel" onClick="DeleteMessage(\'' + Title + '\')">Delete</span>'
		+ '</div></div>';
	$("#messagesDiv").html($("#messagesDiv").html() + newThread);
}

function EditMessage(Title)
{
	var message;
	for (m in Messages)
	{
		if (Messages[m] != null && Messages[m].title == Title)
		{
			message = Messages[m];
		}
	}
	if (message == null)
		return;
		
	var newBody = prompt("Enter a new message body for '" + Title + "'.", message.body);
	if (newBody != null && newBody != message.body)
	{
		message.body = newBody;
	}	
	SaveDataToServer();
}

function DeleteMessage(Title)
{
	var message;
	var newMessages = new Array();
	for (m in Messages)
	{
		if (Messages[m].title != Title)
		{
			newMessages.push(Messages[m]);
		}
	}
	Messages = newMessages;
	SaveDataToServer();
}

function AddMessage()
{
	var title = prompt("Enter a title for your message", "");
	if (title == null || title == "")
	{
		alert("Cannot create a message without a title. Try again, choosing a non blank, unique title.");
		return;
	}
	var message;
	for (m in Messages)
	{
		if (Messages[m] != null && Messages[m].title == title)
		{
			message = Messages[m];
		}
	}
	if (message != null)
	{
		alert("A message already exists with that title. Try again, choosing a non blank, unique title.");
		return;
	}
	var name = prompt("Enter the authors name.", "");
	var body = prompt("Enter the body text of the message", "");
	var time = new Date();
	var m = new Message(title, name, time.toString(), body);
	Messages.push(m);
	SaveDataToServer();
}

// STATUS UPDATE SECTION
function EditStatus()
{
	var newStatus = prompt("Enter a new status message", StatusString);
	if (newStatus != null)
	{
		StatusString = newStatus;
		SaveDataToServer();
	}
}

// MISC FUNCTIONS SECTION
//  Retrieves the other config map for the currently selected XenCenter object and passes it on to the callback function
function GetOtherConfig(Callback)
{
	var tmprpc;
	function GetCurrentOtherConfig() 
	{
		var toExec = "tmprpc." + window.external.SelectedObjectType + ".get_other_config(Callback, window.external.SessionUuid, window.external.SelectedObjectRef);";
		eval(toExec);
	}
	tmprpc= new $.rpc(
		"xml", 
		GetCurrentOtherConfig,
		null,
		[window.external.SelectedObjectType + ".get_other_config"]
	);	
}

// The result object of any xmlrpc call to the server contains:
// - a result field which indicates whether it was succesfull or not,
// - a value field containing any returned data in json
// - an error description field containing any error information
// This function checks for success, displays any relevant errors, and returns a json object that corresponds to the value field 
function CheckResult(Result) 
{
	var myResult=Result.result;
	if(myResult.Status=="Failure") 
	{
		var message=myResult.ErrorDescription[0];
		for(var i=1; i<myResult.ErrorDescription.length; i++) 
		{
			message+=","+myResult.ErrorDescription[i];
		}
		$("#content").css({"display" : "none"});
		$("#errorContent").css({"display" : ""});
		$("#errorMessage").html(message);
		return;
	}
	if (myResult.Value == "")
	{
		return;
	}
	myResult = eval("("+myResult.Value+")");
	return myResult;
}

// TAGS UPDATE SECTION
// This pair of methods chain to retrieve the server objects tags from the server and display them. There is no writing to the tags field on the server.
function RefreshTags()
{
	var tmprpc;
	function RetrieveTags() 
	{
		var toExec = "tmprpc." + window.external.SelectedObjectType + ".get_tags(ShowTags, window.external.SessionUuid, window.external.SelectedObjectRef);";
		eval(toExec);
	}
	tmprpc= new $.rpc(
		"xml", 
		RetrieveTags,
		null,
		[window.external.SelectedObjectType + ".get_tags"])
}

function ShowTags(TagsResult)
{
	var result = CheckResult(TagsResult);
	if (result == null)
	{
		return;
	}
	var tags = "";
	for (t in result)
	{
		tags = tags + result[t] + ", ";
	}
	tags = tags.substring(0, tags.length - 2);
	if (tags == "")
	{
		tags = "None";
	}
	$("#tagsText").html(tags);
}

// DESCRIPTION UPDATE SECTION
// This pair of methods chain to retrieve the description field from the server and display it. There is no writing to the description field on the server.
function RefreshDescription()
{
	var tmprpc;
	function RetrieveDescription() 
	{
		var toExec = "tmprpc." + window.external.SelectedObjectType + ".get_name_description(ShowDescription, window.external.SessionUuid, window.external.SelectedObjectRef);";
		eval(toExec);
	}
	tmprpc= new $.rpc(
		"xml", 
		RetrieveDescription,
		null,
		[window.external.SelectedObjectType + ".get_name_description"])
}

function ShowDescription(DescriptionResult)
{
	var result = CheckResult(DescriptionResult);
	if (result == null)
	{
		$("#descriptionText").html("None");
		return;
	}
	$("#descriptionText").html(result);
}

// SAVE DATA SECTION
// This chain of methods will clear the current message array and status string on the server, and save the local copy there instead. 
// It finishes with a refresh that populates the page using the new server values as a sanity check.
// SaveDataToServer -> ClearMessages -> WriteMessages -> ClearStatus -> WriteStatus -> RefreshMessagesAndStatus -> GetOtherConfig -> DrawMessagesAndStatus
function SaveDataToServer()
{
	ClearMessages();
}

function ClearMessages()
{
	var tmprpc;
	function RemoveMessagesFromOtherConfig() 
	{
		var toExec = "tmprpc." + window.external.SelectedObjectType + ".remove_from_other_config(WriteMessages, window.external.SessionUuid, window.external.SelectedObjectRef, '" + MessageOtherConfigKey + "');";
		eval(toExec);
	}
	tmprpc= new $.rpc(
		"xml", 
		RemoveMessagesFromOtherConfig,
		null,
		[window.external.SelectedObjectType + ".remove_from_other_config"]
	);	
}

function WriteMessages(RemoveMessagesResult)
{
	var result = CheckResult(RemoveMessagesResult);
	var tmprpc;
	function WriteMessagesToOtherConfig() 
	{
		var toExec = "tmprpc." + window.external.SelectedObjectType + ".add_to_other_config(ClearStatus, window.external.SessionUuid, window.external.SelectedObjectRef, '" + MessageOtherConfigKey + "', escape(output));";
		eval(toExec);
	}
	var output = "[";
	if (Messages.length > 0)
	{
		for (m in Messages)
		{
			output = output + MessageToJson(Messages[m]) + ",";
		}
		output = output.substring(0, output.length-1);
	}
	output = output + "]";
	tmprpc= new $.rpc(
		"xml", 
		WriteMessagesToOtherConfig,
		null,
		[window.external.SelectedObjectType + ".add_to_other_config"]
	);	
}

function ClearStatus()
{
	var tmprpc;
	function RemoveStatusFromOtherConfig() 
	{
		var toExec = "tmprpc." + window.external.SelectedObjectType + ".remove_from_other_config(WriteStatus, window.external.SessionUuid, window.external.SelectedObjectRef, '" + StatusStringOtherConfigKey + "');";
		eval(toExec);
	}
	tmprpc= new $.rpc(
		"xml", 
		RemoveStatusFromOtherConfig,
		null,
		[window.external.SelectedObjectType + ".remove_from_other_config"]
	);	
}

function WriteStatus(RemoveStatusResult)
{
	var result = CheckResult(RemoveStatusResult);
	var tmprpc;
	function WriteStatusToOtherConfig() 
	{
		var toExec = "tmprpc." + window.external.SelectedObjectType + ".add_to_other_config(RefreshMessagesAndStatus, window.external.SessionUuid, window.external.SelectedObjectRef, '" + StatusStringOtherConfigKey + "', escape(StatusString));";
		eval(toExec);
	}
	tmprpc= new $.rpc(
		"xml", 
		WriteStatusToOtherConfig,
		null,
		[window.external.SelectedObjectType + ".add_to_other_config"]
	);	
}

function RefreshMessagesAndStatus()
{
	GetOtherConfig(DrawMessagesAndStatus);
}

function DrawMessagesAndStatus(OtherConfigResult)
{
	var oConf = CheckResult(OtherConfigResult);
	if (oConf == null)
	{
		// this normally means there was an error in CheckResult, so we dont have any data to draw from
		return;
	}
	var data = oConf[MessageOtherConfigKey];
	var data_unesc = unescape(data);
	var messagesFromServer = eval("(" + data_unesc + ")");	
	if (messagesFromServer != null)
	{
		// on the server all the message string fields are escaped, need to unescape them now
		for (m in messagesFromServer)
		{
			for (s in messagesFromServer[m])
			{
				if(typeof messagesFromServer[m][s] == "string")
				{
					messagesFromServer[m][s] = unescape(messagesFromServer[m][s]);
				}
			}
		}
		Messages = messagesFromServer;
	}
	else
	{
		// The key doesn't exist on the server yet, so there are no messages
		Messages.length = 0;
	}
	// Remove all the messages we are currently displaying before redrawing from the updated message list
	$("#messagesDiv").html("");
	for (m in Messages)
	{
		DrawMessage(Messages[m].title, Messages[m].name, Messages[m].date, Messages[m].body);
	}
	//Now refresh the status messages
	if (!(oConf[StatusStringOtherConfigKey]))
	{
		StatusString = "None";
	}
	else
	{
		StatusString = unescape(oConf[StatusStringOtherConfigKey]);
	}
	$("#statusText").html(StatusString);	
}