/*
 This plugin for jquery was written by kamanashisroy and is available at http://plugins.jquery.com/project/rpc
 The code is licensed under GPL 2 http://www.gnu.org/licenses/old-licenses/gpl-2.0.html
 
 It has been modified for use with XenCenter 5.6 to enable XenCenter XML-RPC passthrough
*/

window.jQuery = window.jQuery || {};

jQuery.rpc = function(dataType, onLoadCallback, version, methods) {
	return new (function(dataType, onLoadCallback, version) {
		version = version || "1.0";
		dataType = dataType || "json";
		if(dataType != "json" && dataType != "xml") {
			new Error("IllegalArgument: Unsupported data type");
		}

	        var _self = this;

	        function pad2(f) {
			if(f<=9) {
				return "0"+f;
			} else {
				return ""+f;
			}
		}
		var serializeToXml = function(data) {
			switch (typeof data) {
			case 'boolean':
				return '<boolean>'+ ((data) ? '1' : '0') +'</boolean>';
			case 'number':
				var parsed = parseInt(data);
				if(parsed == data) {
					return '<int>'+ data +'</int>';
				}
				return '<double>'+ data +'</double>';
			case 'string':
				return '<string>'+ data +'</string>';
			case 'object':
				if(data instanceof Date) {
					return '<dateTime.iso8601>'+ data.getFullYear() + pad2(data.getMonth()) + pad2(data.getDate()) +'T'+ pad2(data.getHours()) +':'+ pad2(data.getMinutes()) +':'+ pad2(data.getSeconds()) +'</dateTime.iso8601>';
				} else if(data instanceof Array) {
					var ret = '<array><data>'+"\n";
					for (var i=0; i < data.length; i++) {
						ret += '  <value>'+ serializeToXml(data[i]) +"</value>\n";
					}
					ret += '</data></array>';
					return ret;
				} else {
					var ret = '<struct>'+"\n";
					jQuery.each(data, function(key, value) {
						ret += "  <member><name>"+ key +"</name><value>";
						ret += serializeToXml(value) +"</value></member>\n";
					});
					ret += '</struct>';
					return ret;
				}
			}
		}
		var xmlRpc = function(method, params) {
			var ret = '<?xml version="'+version+'"?><methodCall><methodName>'+method+'</methodName><params>';
			for(var i=0; i<params.length; i++) {
				ret += "<param><value>"+serializeToXml(params[i])+"</value></param>";
			}
			ret += "</params></methodCall>";
			return ret;
		}
		
		var rpc_contents = {
			'xml':'text/xml'
			,'json':'application/json'
		};
		var _rpc = function(method) {
			var params = [];
			var async; // whether we're async or not
			var init; // start of the method's arguments in the arguments array
			var callback;

			if(arguments.length > 1 && typeof(arguments[1])=="function") {
				callback = arguments[1];
				init=2;
				async=true;
			} else {
				init=1;
				async=false;
			}

			for (var i=init; i<arguments.length; i++) {
				params.push(arguments[i]);
			}
			// console.log(params);
			var data;
			if(dataType == 'json') {
				data = {"version":version, "method":method, "params":params};
			} else {
				data = xmlRpc(method, params);
			}
			window.external.writeXML(callback.toString(), data);
		};
		
		function populate(methods) {
			// console.log(json);
			/* get the functions */
			var proc = null;
			for(var i = 0; i<methods.length; i++) {
				proc = methods[i];
				var obj = _self;
				var objStack = proc.split(/\./);
				for(var j = 0; j < (objStack.length - 1); j++){
					obj[objStack[j]] = obj[objStack[j]] || {};
					obj = obj[objStack[j]];
				}
				/* add the new procedure */
				obj[objStack[j]] = (
					function(method, obj) {
						var _outer = {"method":method,"rpc":_rpc};
						return function() {
							var params = [];
							params.push(_outer.method);
							for (var i=0; i<arguments.length; i++) {
								params.push(arguments[i]);
							}
							return _rpc.apply(_self, params);
						}
					}
				)(proc, _rpc);
			}
			// console.log('Load was performed.');
		}

		function asyncCallback(json) {
			populate(json.result);
			if(onLoadCallback) {
				onLoadCallback(_self);
			}
		}

		if(!methods) {
			_rpc("system.listMethods", asyncCallback);
		} else {
			populate(methods);
			if(onLoadCallback) {
			    // not sure this works - the intention is to call the callback as soon as this
			    // javascript function returns control back to the browser, to emulate the behaviour
			    // that the system.listMethods approach
				setTimeout(function(){onLoadCallback(_self);},0);
			}
		}
	
	})(dataType, onLoadCallback, version);
};

function XenCenterXML(methodCallback, data)
{
	var parseXmlValue = function(node) {
		var jnode = jQuery(node);
		childs = jnode.children();
		// String not enclosed in a <string> tag
		if(childs.length==0) {
			var s="";
			for(var j=0; j<jnode[0].childNodes.length;j++) {
				s+=new String(jnode[0].childNodes[j].nodeValue);
			}
			return s;
		}
		for(var i=0; i < childs.length; i++) {
			switch(childs[i].tagName) {
			case 'boolean':
				return (jQuery(childs[i]).text() == 1);
			case 'int':
				return parseInt(jQuery(childs[i]).text());
			case 'double':
				return parseFloat(jQuery(childs[i]).text());
			case "string":
				return jQuery(childs[i]).text();
			case "array":
				var ret = [];
				jQuery("> data > value", childs[i]).each(
					function() {
						ret.push(parseXmlValue(this));
					}
				);
				return ret;
			case "struct":
				var ret = {};
				jQuery("> member", childs[i]).each(
					function() {
						ret[jQuery( "> name", this).text()] = parseXmlValue(jQuery("value", this));
					}
				);
				return ret;
			case "dateTime.iso8601":
				/* TODO: fill me :( */
				return NULL;
			}
		}
	}
	var parseXmlResponse = function(data) {

		var dataObj = new ActiveXObject( 'Microsoft.XMLDOM' );
		dataObj.loadXML( data); 
		var ret = {};			
		jQuery("methodResponse params param > value", dataObj).each(
			function(index) {
				ret.result = parseXmlValue(this);
			}
		);
		jQuery("methodResponse fault > value", dataObj).each(
			function(index) {
				ret.error = parseXmlValue(this);
			}
		);
		return ret;
	}
	var fn = window[methodCallback];
	var out = parseXmlResponse(data);
	fn(out);
}

