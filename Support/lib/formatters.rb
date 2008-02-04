class Formatters
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