require 'interactive_rspec/version'
require 'rspec'

module InteractiveRspec
  def self.report(result)
    e = describe.example

    ret = RSpec.configuration.reporter.report(1) do |r|
      r.instance_variable_set '@example_count', 1
      if result.is_a? Exception
        e.send :record, :status => 'failed', :finished_at => Time.now, :run_time => 0, :exception => result
        r.example_failed e
        false
      else
        r.example_passed e
        true
      end
    end
    RSpec.reset
    ret
  end
end
