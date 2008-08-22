module ConfigHelper
  def config_text_field(local_or_global, config_key, options = {})
    content_tag :input, {:type => "text", :value => git.config[local_or_global, config_key], :onchange => "dispatch({controller: 'config', action: 'set', scope: '#{local_or_global}', key: '#{config_key}', value: $F(this)})"}.merge(options)
  end
end