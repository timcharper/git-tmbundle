module FormatHelpers
  module TagHelper
    # Adapted from RubyOnRails
    BOOLEAN_ATTRIBUTES = %w(disabled readonly multiple)
    def content_tag_string(name, content = nil, options = {}, escape = true, close = true)
      "#{content_tag_string_open(name, options)}#{content}#{content_tag_string_close(name)}"
    end
    
    def content_tag_string_open(name, options, escape = true)
      tag_option_string = tag_options(options, escape) if options
      "<#{name}#{tag_option_string}>"
    end
    
    def content_tag_string_close(name)
      "</#{name}>"
    end
    
    def content_tag(name, content_or_options_with_block = nil, options = nil, escape = true, &block)
      if block_given?
        options = content_or_options_with_block if content_or_options_with_block.is_a?(Hash)
        STDOUT << content_tag_string_open(name, options, escape)
        yield
        STDOUT << content_tag_string_close(name)
      else
        content = content_or_options_with_block
        content_tag_string(name, content, options, escape)
      end
    end
    
    def tag_options(options, escape = true)
      unless options.blank?
        attrs = []
        if escape
          options.each do |key, value|
            next unless value
            key = key.to_s
            value = BOOLEAN_ATTRIBUTES.include?(key) ? key : escape_once(value)
            attrs << %(#{key}="#{value}")
          end
        else
          attrs = options.map { |key, value| %(#{key}="#{value}") }
        end
        " #{attrs.sort * ' '}" unless attrs.empty?
      end
    end
    
    def htmlize_attr(str)
      str.to_s.gsub(/"/, "&quot;").gsub("<", "&lt;").gsub(">", "&gt;")
    end

    alias :escape_once :htmlize_attr
    
  end
end