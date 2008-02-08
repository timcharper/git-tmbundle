require File.dirname(__FILE__) + '/../date_helpers.rb'
class Formatters
  class Push
    include Formatters::FormatterHelpers
    def initialize
      @header = "Push"
    end
    
    def layout(&block)
      render("layout", &block)
    end
  end
end