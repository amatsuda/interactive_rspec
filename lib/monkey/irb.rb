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
    def irspec
      InteractiveRspec.configure
      pushws new_extended_example_group
    end
  end
end
