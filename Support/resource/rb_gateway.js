/* Git JS gateway */
/* Tim Harper (tim.harper at leadmediapartners.org) */
function e_sh(str) { 
	return '"' + (str.toString().replace('"', '\\"')) + '"';
}

function exec(command, params) {
	params = params.map(function(a) { return e_sh(a) }).join(" ")
	
	return TextMate.system(command + " " + params, null)
}

function ENV(var_name) {
	return TextMate.system("echo $" + var_name, null).outputString.strip();
}

function gateway_command(command, params) {
	// var cmd = arguments.shift
	// var params = arguments
	try {
		command = "ruby " + e_sh(TM_BUNDLE_PATH) + "/Support/gateway/" + command
		return exec(command, params).outputString
	}
	catch(err) {
		return "ERROR!" + err;
	}
}

TM_BUNDLE_PATH = ENV('TM_BUNDLE_PATH')