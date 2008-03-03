class ApplicationController
  include ApplicationHelper
  attr_accessor :params
  class << self
    attr_accessor :layout
    
    def layout
      @layout 
    end
  end
  
  def with_layout(&block)
    render "/layouts/application", &block
  end
  
  def call(action, _params = {})
    self.params = _params
    
    if params[:layout].to_s == "false"
      send(action)
    else
      with_layout { send(action) }
    end
  end
  
  def self.call(action, params = {})
    new.call(action, params)
  end
  
  def render(name, options = {}, &block)
    name = "#{name}.html.erb" unless name.include?(".")
    sub_dir = name.include?("/") ? "" : self.class.template_root
    ___template___ = File.read( File.join( VIEWS_ROOT, sub_dir, name))
    
    if options[:locals]
      __v__ = options[:locals].values
      eval(options[:locals].keys * ", " + " = __v__.length == 1 ? __v__[0] : __v__") 
    end
    
    ERBStdout.new(___template___, nil, "-", "STDOUT").run(binding)
  end
  
  def render_component(params = {})
    dispatch(params)
  end
  
  def self.template_root
    to_s.gsub("::", "/").underscore
  end
  
end
