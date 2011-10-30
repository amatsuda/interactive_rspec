require 'interactive_rspec/version'
require 'rspec'
require 'irb'
require 'irb/completion'

module InteractiveRspec
  class << self
    attr_accessor :rspec_mode
  end
end

require File.join(File.dirname(__FILE__), 'monkey/irb')
require File.join(File.dirname(__FILE__), 'monkey/rspec')

module InteractiveRspec
  def self.start(options = {})
    configure if {:configure => true}.merge(options)
    IRB.start_with_context new_extended_example_group
  end

  def self.configure
    RSpec.configure do |c|
      c.output_stream = STDOUT
      c.color_enabled = true
    end
  end

  def self.new_extended_example_group
    eg = describe
    RSpec.configuration.expectation_frameworks.each do |framework|
      eg.extend framework
    end
    eg.extend RSpec.configuration.mock_framework
  end

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

  def self.run_specs(specs)
    # to avoid auto_run at_exit
    RSpec::Core::Runner.instance_variable_set '@autorun_disabled', true
    config_options = RSpec::Core::ConfigurationOptions.new ['--color', specs]
    config_options.parse_options

    RSpec::Core::CommandLine.new(config_options, RSpec.configuration, RSpec.world).run(STDERR, STDOUT)
  end
end
