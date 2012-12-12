require 'interactive_rspec/version'
require 'rspec'
require 'irb'
require 'irb/completion'

module InteractiveRspec
  class << self
    attr_accessor :rspec_mode
  end
end

require 'interactive_rspec/monkey/irb'
require 'interactive_rspec/monkey/rspec'

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
    #TODO load spec_helper.rb?
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

  # @param [Exception or true]
  def self.report(result)
    e = describe.example

    ret = RSpec.configuration.reporter.report(1) do |r|
      r.instance_variable_set '@example_count', 1
      if result.is_a? Exception
        result.extend(RSpec::Core::Example::NotPendingExampleFixed) if defined?(RSpec::Core::Example::NotPendingExampleFixed) && !result.respond_to?(:pending_fixed?)
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

  def self.run_specs(specs, options = {})
    # to avoid auto_run at_exit
    RSpec::Core::Runner.instance_variable_set '@autorun_disabled', true
    config = ['--color', fuzzy_match(specs)]
    config += ['--line_number', options[:line].to_s] if options[:line]
    config_options = RSpec::Core::ConfigurationOptions.new config
    config_options.parse_options

    RSpec::Core::CommandLine.new(config_options, RSpec.configuration, RSpec.world).run(STDERR, STDOUT)
  end

  def self.fuzzy_match(specs)
    return Dir.glob '**/*_spec.rb' if specs == :all
    [specs, "spec/#{specs}", "#{specs}.rb", "#{specs}_spec.rb", "spec/#{specs}.rb", "spec/#{specs}_spec.rb", "#{specs}/**/*_spec.rb", "spec/#{specs}/**/*_spec.rb"].each do |pattern|
      files = Dir.glob pattern
      return files if files.any?
    end
    specs
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

InteractiveRSpec = InteractiveRspec
