module SCM
  class Git
    class SubmoduleBase
      attr_accessor :base
      def initialize(base)
        @base = base
      end
    end
  end
end
      