SPEC_ROOT = File.dirname(__FILE__)
FIXTURES_DIR = "#{SPEC_ROOT}/fixtures"
require SPEC_ROOT + '/../lib/git.rb'
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
      Object.class_eval do 
        def puts(*args)
        args.each{ |arg| Object::STDOUT.puts arg}
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

def stub_command_runner(klass)
  klass.class_eval do
    def self.command_output
      @command_output ||= []
    end
    
    def command_output
      self.class.command_output
    end
    
    def command(*args)
      command_output.shift
    end
    
    def popen_command(*args)
      StringIO.new(command_output.shift)
    end
    
    def chdir_base
      true
    end
  end
end