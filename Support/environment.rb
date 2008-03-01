ROOT = File.dirname(__FILE__)
LIB_ROOT = ROOT + "/lib"
CONTROLLERS_ROOT = ROOT + "/app/controllers"
VIEWS_ROOT = ROOT + "/app/views"
%w[formatters git ruby_tm_helpers string auto_load].each do |filename|
  require "#{LIB_ROOT}/#{filename}.rb"
end
require ENV['TM_SUPPORT_PATH'] + '/lib/escape.rb'
require 'shellwords'
require 'set'

def dispatch(params = {})
  raise "must supply a controller to use!" unless controller = params[:controller]
  params[:action] ||= "index"
  controller_class = "#{controller}_controller".classify.constantize
  controller_class.call(params[:action], params)
end
