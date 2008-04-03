module SCM
  class Git
    class CommandProxyBase
      attr_accessor :base
      def initialize(base)
        @base = base
      end
    end
  end
end
      