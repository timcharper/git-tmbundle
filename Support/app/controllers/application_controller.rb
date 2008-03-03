class ApplicationController
  include ApplicationHelper
  attr_accessor :params
  class << self
    attr_writer :layouts_conditions
    
    def layouts_conditions
      @layouts_conditions ||= []
    end
    
    def layout(layout, conditions = {})
      layout = "/layouts/#{layout}" unless layout.to_s.include?("/")
      raise "bad params!" unless conditions.is_a?(Hash)
      layouts_conditions << [layout, conditions]
    end
    
    def layout_for_action(action)
      return "/layouts/application" if layouts_conditions.empty?
      layouts_conditions.each do |layout, condition|
        if condition[:except]
          next if condition[:except].map{|c| c.to_s}.include?(action.to_s)
        end
        
        if condition[:only]
          next unless condition[:only].map{|c| c.to_s}.include?(action.to_s)
        end
        
        return layout
      end
      nil
    end
  end
  
  def with_layout(action = nil, &block)
    this_actions_layout = self.class.layout_for_action(action || params[:action])
    if this_actions_layout
      render this_actions_layout, &block
    else
      yield
    end
  end
  
  def call(action, _params = {})
    self.params = _params
    params[:action] = action.to_s
    
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
