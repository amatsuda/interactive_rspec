module RSpec
  module Matchers
    class OperatorMatcher
      def eval_match_with_reporting(actual, operator, expected)
        InteractiveRspec.report begin
          eval_match_without_reporting(actual, operator, expected)
        rescue RSpec::Expectations::ExpectationNotMetError => err
          err
        end
      end
      alias_method :eval_match_without_reporting, :eval_match
      alias_method :eval_match, :eval_match_with_reporting
    end
  end

  module Expectations
    class PositiveExpectationHandler
      class << self
        unless method_defined? :handle_matcher_with_reporting
          def handle_matcher_with_reporting(actual, matcher, message=nil, &block)
            begin
              result = handle_matcher_without_reporting actual, matcher, message, &block
              if result.class == TrueClass
                InteractiveRspec.report result
              else
                result
              end
            rescue RSpec::Expectations::ExpectationNotMetError => err
              InteractiveRspec.report err
              false
            end
          end

          alias_method :handle_matcher_without_reporting, :handle_matcher
          alias_method :handle_matcher, :handle_matcher_with_reporting
        end
      end
    end
  end
end
