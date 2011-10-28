module RSpec
  module Core
    class Example
      def inspect
        ret = RSpec.configuration.reporter.report(1) do |r|
          self.run ExampleGroup.new, r
        end
        RSpec.reset
        ret
      end
    end
  end
end
