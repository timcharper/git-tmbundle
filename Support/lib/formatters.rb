require 'erb'

class Formatters
  module FormatterHelpers
    def resource_url(filename)
      "file://#{ENV['TM_BUNDLE_SUPPORT']}/resource/#{filename}"
    end
    
    def short_rev(rev)
      rev.to_s[0..7]
    end
    
    def render(name, options = {}, &block)
      name = "#{name}.html.erb" unless name.include?(".")
      sub_dir = self.class.to_s.gsub("::", "/")
      ___template___ = File.read( File.join( File.dirname(__FILE__), sub_dir, name))
      
      if options[:locals]
        __v__ = options[:locals].values
        eval(options[:locals].keys * ", " + " = __v__.length == 1 ? __v__[0] : __v__") 
      end
      
      ERB.new(___template___, nil, "-").result(binding)
    end
    
    def select_box(name, select_options = [], options = {})
      options[:name] ||= name
      options[:id] ||= name
      # puts select_options.inspect
      <<-EOF
        <select name='#{options[:name]}' id='#{options[:id]}' onchange="#{options[:onchange]}" style='width:100%'>
          #{select_options}
        </select>
      EOF
    end
  
    def options_for_select(select_options = [], selected_value = nil)
      output = ""
    
      select_options.each do |name, val|
        selected = (val == selected_value) ? "selected='true'" : ""
        output << "<option value='#{val}' #{selected}>#{htmlize(name)}</option>"
      end
    
      output
    end
    
    def make_non_breaking(output)
      htmlize(output.to_s.strip).gsub(" ", "&nbsp;")
    end
    
    
    def htmlize_attr(str)
      str.to_s.gsub(/"/, "&quot;").gsub("<", "&lt;").gsub(">", "&gt;")
    end
    
    def javascript_include_tag(*params)
      file_names = []
      params = params.map {|p| p.include?(".js") ? p : "#{p}.js"}
      params.map do |p|
        %Q{<script type='text/javascript' src="#{resource_url(p)}"></script>}
      end
    end
  end
  
  def self.const_missing(name)
    @last_try||=nil
    raise if @last_try==name
    @last_try = name
    
    file = File.dirname(__FILE__) + "/formatters/#{name.to_s.downcase}.rb"
    require file
    klass = const_get(name)
  rescue LoadError
    raise "Class not found: #{name} (couldn't find file formatters/#{name.to_s.downcase})"
  end
end