SPEC_ROOT = File.dirname(__FILE__)
FIXTURES_DIR = "#{SPEC_ROOT}/fixtures"
require SPEC_ROOT + '/../environment.rb'
require 'rubygems'
require 'stringio'
require 'hpricot'
require SPEC_ROOT + "/../tmvc/spec/spec_helpers.rb"

SpecHelpers::PUTS_CAPTURE_CLASSES << ::Git

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

def exit_with_output_status
end

[:exit_show_html, :exit_discard, :exit_show_tool_tip].each do |exit_method|
  Object.send :define_method, exit_method do
    $exit_status = exit_method
  end
end

class Object
  def self.singleton_new(*args)
    return @new if @new
    @new = new(*args)
    self.stub!(:new).and_return(@new)
    @new
  end
end