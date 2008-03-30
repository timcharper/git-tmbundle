TMVC_ROOT = File.dirname(__FILE__)

ROOT = TMVC_ROOT + "/.."
CONTROLLERS_ROOT = ROOT + "/app/controllers"
HELPERS_ROOT = ROOT + '/app/helpers'
VIEWS_ROOT = ROOT + "/app/views"


%w[erb_stdout html_helpers application_helper application_controller].each do |filename|
  require TMVC_ROOT + "/lib/#{filename}.rb"
end

require(HELPERS_ROOT + "/application_helper.rb") if File.exist?(HELPERS_ROOT + "/application_helper.rb")


at_exit { 
  if $exit_status
    exit $exit_status
  end
}

def dispatch(params = {})
  begin
    $dispatched = true
    params = parse_dispatch_args if params.is_a?(Array)
    
    raise "must supply a controller to use!" unless controller = params[:controller]
    params[:action] ||= "index"
    controller_class = "#{controller}_controller".classify.constantize
    controller_class.call(params[:action], params)
  rescue => e
    puts htmlize($!)
    puts htmlize($!.backtrace)
  end
end

def parse_dispatch_args(args = [])
  params = args.inject({}) do |hash, arg|
    parts = arg.scan(/(.+?)=(.+)/).flatten
    next hash if parts.empty?
    key = parts.first.to_sym
    value = parts.last
    hash[key] = value
    hash
  end
end

