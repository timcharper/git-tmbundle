ROOT = File.dirname(__FILE__)
LIB_ROOT = ROOT + "/lib"
CONTROLLERS_ROOT = ROOT + "/app/controllers"
VIEWS_ROOT = ROOT + "/app/views"
%w[string auto_load ruby_tm_helpers date_helpers formatters git].each do |filename|
  require "#{LIB_ROOT}/#{filename}.rb"
end
require ENV['TM_SUPPORT_PATH'] + '/lib/escape.rb'
require 'shellwords'
require 'set'
require "#{ROOT}/dispatch" unless $dispatch_loaded

def shorten(path, base = nil)
  return if path.blank?
  base = base.gsub(/\/$/, "") if base
  project_path = 
  home_path = ENV['HOME']
  case
  when base && path =~ /^#{Regexp.escape base}\/(.+)$/
    $1
  when base && path =~ /^#{Regexp.escape base}\/?$/
    "./"
  when path == project_path
    File.basename(path)
  when ENV['TM_PROJECT_DIRECTORY'] && path =~ /^#{Regexp.escape ENV['TM_PROJECT_DIRECTORY']}\/(.+)$/
    $1
  when ENV['HOME'] && path =~ /^#{Regexp.escape ENV['HOME']}\/(.+)$/
    '~/' + $1
  else
    path
  end
end