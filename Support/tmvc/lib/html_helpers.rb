module HtmlHelpers
  include ERB::Util
  
  def path_for(default_path, path)
    if path.include?("/")
      path
    else
      default_path(path)
    end
  end
    
protected  
  def resource_url(filename)
    "file://#{ENV['TM_BUNDLE_SUPPORT']}/resource/#{filename}"
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
  
  
  def e_js(str)
    str.to_s.gsub(/"/, '\"').gsub("\n", '\n')
  end
  
  def javascript_include_tag(*params)
    file_names = []
    params = params.map {|p| p.include?(".js") ? p : "#{p}.js"}
    params.map do |p|
      content_tag :script, "", :type => "text/javascript", :src => resource_url(p)
    end
  end
  
  def options_for_javascript(options = {})
    output = options.map { |key, value| "#{key}: \"#{e_js(value)}\"" }
    "{" + (output.sort * ", ") + "}"
  end
  
  def link_to_remote(name, options = {})
    params = options.delete(:params)
    js = "dispatch(#{options_for_javascript(params)})"
    
    content_tag(:a, name, :href => "javascript:void(0)", :onclick => js)
  end
  
  include FormatHelpers::TagHelper
end

