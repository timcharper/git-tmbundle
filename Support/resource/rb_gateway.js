/* Git JS gateway */
/* Tim Harper (tim.harper at leadmediapartners.org) */
function e_sh(str) { 
  return '"' + (str.toString().gsub('"', '\\"')) + '"';
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
    command = "ruby " + e_sh(TM_BUNDLE_SUPPORT) + "/gateway/" + command
    return exec(command, params).outputString
  }
  catch(err) {
    return "ERROR!" + err;
  }
}


function dispatch(params) {
  try {
    params = $H(params).map(function(pair) { return(pair.key + "=" + pair.value.toString())})
    command = "ruby " + e_sh(TM_BUNDLE_SUPPORT) + "/dispatch.rb";
    // return params.map(function(a) { return e_sh(a) }).join(" ")
    return exec(command, params).outputString
  }
  catch(err) {
    return "ERROR!" + err;
  }
}

function dispatch_streaming(iframe_target, params) {
  params['streaming']="true"
  port = dispatch(params)
  $(iframe_target).src = "http://127.0.0.1:" + port + "/"
  return false;
}

TM_BUNDLE_SUPPORT = ENV('TM_BUNDLE_SUPPORT')