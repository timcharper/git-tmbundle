require File.dirname(__FILE__) + "/environment.rb"

def dispatch(params = {})
  raise "must supply a controller to use!" unless controller = params[:controller]
  params[:action] ||= "index"
  controller_class = "#{controller}_controller".classify.constantize
  controller_class.call(params[:action], params)
end

if $0 == __FILE__ && ! $dispatched
  begin
    $dispatched = true
    params = ARGV.inject({}) do |hash, arg|
      parts = arg.scan(/(.+?)=(.+)/).flatten
      next hash if parts.empty?
      key = parts.first.to_sym
      value = parts.last
      hash[key] = value
      hash
    end
    dispatch(params)
  rescue => e
    puts htmlize($!)
    puts htmlize($!.backtrace)
  end
end