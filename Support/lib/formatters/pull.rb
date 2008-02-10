class Formatters
  class Pull < Push
    def initialize(*args)
      super
      @header = "Pull"
    end
    
    def self.template_root
      Push.template_root
    end
  end
end