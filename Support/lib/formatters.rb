class Formatters
  module FormatterHelpers
    def resource_url(filename)
      "file://#{ENV['TM_BUNDLE_SUPPORT']}/resource/#{filename}"
    end
    
    def short_rev(rev)
      rev.to_s[0..7]
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