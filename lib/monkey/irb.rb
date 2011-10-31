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
    def irspec(specs = nil)
      #TODO check if already in irspec
      InteractiveRspec.configure
      if specs
        InteractiveRspec.switch_rails_env do
          InteractiveRspec.run_specs specs
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
      nil
    end
  end
end
