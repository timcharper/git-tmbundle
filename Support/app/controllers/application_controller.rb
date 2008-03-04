class ApplicationController
  include ApplicationHelper
  attr_accessor :params
  class << self
    attr_writer :layouts_conditions
    
    def layouts_conditions
      @layouts_conditions ||= []
    end
    
    def layout(layout, conditions = {})
      layout = "/layouts/#{layout}" if layout && !layout.to_s.include?("/")
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
  
  def render(__name__, __options__ = {}, &block)
    __name__ = "#{__name__}.html.erb" unless __name__.include?(".")
    __sub_dir__ = __name__.include?("/") ? "" : self.class.template_root
    __template_path__ = File.join( VIEWS_ROOT, __sub_dir__, __name__)
    ___template___ = File.read( __template_path__)
    
    if __options__[:locals]
      __v__ = __options__[:locals].values
      eval(__options__[:locals].keys * ", " + " = __v__.length == 1 ? __v__[0] : __v__") 
    end
    
    __erb__ = ERBStdout.new(___template___, nil, "-", "STDOUT")
    __erb__.filename = __template_path__
    __erb__.run(binding)
  end
  
  def render_component(params = {})
    dispatch(params)
  end
  
  def self.template_root
    to_s.gsub("::", "/").underscore.gsub(/_controller$/, "")
  end
  
  def content_for(name, &block)
    var_name = "@content_for_#{name}"
    content = instance_variable_get(var_name) || ""
    content << capture_output(&block)
    instance_variable_set(var_name, content)
    ""
  end
  
  private
    def set_constant_forced(klass, constant_name, constant)
      klass.class_eval do
        remove_const(constant_name) if const_defined?(constant_name)
        const_set(constant_name, constant)
      end
    end
  
    def capture_output(&block)
      require 'stringio'
      
      old_stdout = Object::STDOUT
      io_stream = StringIO.new
      begin 
        set_constant_forced(Object, "STDOUT", io_stream)
        [::Git, ::ApplicationController, ::Formatters].each do |klass| 
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
