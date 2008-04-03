/* Git JS gateway */
/* Tim Harper (tim.harper at leadmediapartners.org) */
function e_sh(str) { 
  return '"' + (str.toString().gsub('"', '\\"').gsub('\\$', '\\$')) + '"';
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

function dispatch_streaming(iframe_target, options) {
  new StreamingDispatchExecuter(iframe_target, options);
  return false;
}

StreamingDispatchExecuter = Class.create();
StreamingDispatchExecuter.prototype = {
  initialize: function(iframe_target, options) {
    this.options = options;
    this.on_complete = options["on_complete"]
    params = options['params']
    params['streaming']="true"
    var parts = dispatch(options['params']).split(",")
    this.port = parts[0];
    this.pid = parts[1];
    $(iframe_target).src = "http://127.0.0.1:" + this.port + "/"
    try {
      new PeriodicalExecuter(function(pe) { 
        if (TextMate.system("kill -0 " + this.pid, null).status == 1) {
          pe.stop()
          if (this.on_complete) this.on_complete();
        }
      }.bindAsEventListener(this), 0.5)
    } catch(e) {$('debug').update(e)}
    
  },
  
}

TM_BUNDLE_SUPPORT = ENV('TM_BUNDLE_SUPPORT')