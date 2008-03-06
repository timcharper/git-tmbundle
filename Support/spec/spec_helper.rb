SPEC_ROOT = File.dirname(__FILE__)
FIXTURES_DIR = "#{SPEC_ROOT}/fixtures"
require SPEC_ROOT + '/../environment.rb'
require 'rubygems'
require 'stringio'
require 'hpricot'

describe "Formatter with layout", :shared => true do
  before(:each) do
    @h = Hpricot(@output)
  end
  
  it "should include a style.css" do
    (@h / "link").map{|s| File.basename(s.attributes["href"])}.should include("style.css")
  end
  
  it "should include a prototype.js" do
    (@h / "script").map{|s| File.basename(s.attributes["src"].to_s)}.should include("prototype.js")
  end
end

module SpecHelpers
  def fixture_file(filename)
    File.read("#{FIXTURES_DIR}/#{filename}")
  end
  
  def set_constant_forced(klass, constant_name, constant)
    klass.class_eval do
      remove_const(constant_name) if const_defined?(constant_name)
      const_set(constant_name, constant)
    end
  end
  
  def capture_output(&block)
    old_stdout = Object::STDOUT
    io_stream = StringIO.new
    begin 
      set_constant_forced(Object, "STDOUT", io_stream)
      [::Git, ::Formatters].each do |klass| 
        klass.class_eval do 
          def puts(*args)
          args.each{ |arg| Object::STDOUT.puts arg}
          end
        end
      end
      yield
    ensure
      set_constant_forced(Object, "STDOUT", old_stdout)
    end
    io_stream.rewind
    io_stream.read
  end
end

class ArrayKeyedHash < Hash
  def []=(*args)
    value = args.pop
    super(args, value)
  end
  
  def [](*args)
    super(args)
  end
end

class Git
  class << self
    def reset_mock!
      command_response.clear
      command_output.clear
      commands_ran.clear
    end
    
    def command_response
      @@command_response ||= ArrayKeyedHash.new
    end
  
    def command_output
      @@command_output ||= []
    end
  
    def commands_ran
      @@commands_ran ||= []
    end
    
    def stubbed_command(*args)
      commands_ran << args
      if command_response.empty?
        command_output.shift
      else
        r = command_response[*args] || ""
        if r.is_a?(Array)
          r.shift
        else
          r
        end
      end
    end
  end
  
  def command(*args)
    Git.stubbed_command(*args)
  end
  
  def popen_command(*args)
    StringIO.new(command(*args))
  end
  
  def chdir_base(*args)
    true
  end
  
  def git_dir(file_or_dir)
    "/base/"
  end
  
  def git_base
    "/base/"
  end
  
  def paths(*args)
    [git_base]
  end
  
  def nca(*args)
    git_base
  end
  
  attr_writer :version
  def version; @version ||= "1.5.4.3"; end
end

[:exit_show_html, :exit_discard, :exit_show_tool_tip].each do |exit_method|
  Object.send :define_method, exit_method do
    $exit_status = exit_method
  end
end