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

    switch_rspec_mode do
      switch_rails_env do
        IRB.start_with_context new_extended_example_group
      end
    end
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

  def self.switch_rspec_mode(&block)
    begin
      InteractiveRspec.rspec_mode = true
      block.call
    ensure
      InteractiveRspec.rspec_mode = false
    end
  end

  def self.switch_rails_env(&block)
    begin
      original_env_rails_env, original_rails_rails_env = nil, nil
      if defined? Rails
        unless Rails.env.test?
          original_env_rails_env = ENV['RAILS_ENV']
          ENV['RAILS_ENV'] = 'test'
          original_rails_rails_env = Rails.env
          load Rails.root.join 'config/environments/test.rb'
          Rails.env = 'test'
          reconnect_active_record
          Bundler.require :test if defined? Bundler
        end
      end

      block.call
    ensure
      if original_env_rails_env || original_rails_rails_env
        ENV['RAILS_ENV'] = original_env_rails_env
        Rails.env = original_rails_rails_env
        load Rails.root.join "config/environments/#{Rails.env}.rb"
        reconnect_active_record
      end
    end
  end

  def self.reconnect_active_record
    if defined? ActiveRecord::Base
      if ActiveRecord::Base.respond_to? :clear_cache
        ActiveRecord::Base.clear_cache!
      else
      end
      ActiveRecord::Base.clear_all_connections!
      ActiveRecord::Base.establish_connection
    end
  end
end
