module IRB
  def IRB.start_with_context(context = nil)
    IRB.setup nil

    if @CONF[:SCRIPT]
      irb = Irb.new(nil, @CONF[:SCRIPT])
    else
      irb = Irb.new WorkSpace.new(TOPLEVEL_BINDING, context)
    end

    @CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
    @CONF[:MAIN_CONTEXT] = irb.context

    trap("SIGINT") do
      irb.signal_handle
    end

    begin
      catch(:IRB_EXIT) do
        irb.eval_input
      end
    ensure
      irb_at_exit
    end
  end

  module ExtendCommandBundle
    def irspec(specs = nil, options = {})
      #TODO check if already in irspec
      # Save configuration to later restore it.
      configuration = RSpec.configuration
      InteractiveRspec.configure
      if specs
        InteractiveRspec.switch_rails_env do
          InteractiveRspec.run_specs specs, options
        end
      else
        InteractiveRspec.switch_rspec_mode do
          InteractiveRspec.switch_rails_env do
#             pushws InteractiveRspec.new_extended_example_group
            irb InteractiveRspec.new_extended_example_group
          end
        end
      end
      RSpec.reset
      # RSpec.reset also clears the configuration, which holds the before and
      # after hooks. Here we restore the configuration to its original state.
      RSpec.instance_eval { @configuration = configuration }
      # Clear filters added during previous run.
      RSpec.configuration.filter_manager = RSpec::Core::FilterManager.new
      # Reset information retained about previously run examples.
      RSpec.configuration.send(:reset)
      nil
    end
  end
end
