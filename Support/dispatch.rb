require File.dirname(__FILE__) + "/environment.rb"

def dispatch(params = {})
  raise "must supply a controller to use!" unless controller = params[:controller]
  params[:action] ||= "index"
  controller_class = "#{controller}_controller".classify.constantize
  controller_class.call(params[:action], params)
end

if $0 == __FILE__
  puts "render the controller here"
end