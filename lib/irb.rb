# Monkey path IRB to provide a secure shell to power users.

module IRB

  
  def IRB.parse_opts
    # Don't touch ARGV, which belongs to the app which called this module.
  end

  def IRB.start
    unless $irb
      IRB.setup nil
      ## maybe set some opts here, as in parse_opts in irb/init.rb?
    end

    workspace = WorkSpace.new(Shell.new)

    if @CONF[:SCRIPT] ## normally, set by parse_opts
      $irb = Irb.new(workspace, @CONF[:SCRIPT])
    else
      $irb = Irb.new(workspace)
    end

    @CONF[:IRB_RC].call($irb.context) if @CONF[:IRB_RC]
    @CONF[:MAIN_CONTEXT] = $irb.context

    trap 'INT' do
      puts "INT"
      $irb.signal_handle
    end
    custom_configuration if defined?(IRB.custom_configuration)

    catch :IRB_EXIT do
      $irb.safe_eval_input
    end

    catch :IN_EVAL do
      puts "IN EVAL"

    end

    ## might want to reset your app's interrupt handler here
  end

  class Irb
    def safe_eval_input
      @scanner.set_prompt do |ltype, indent, continue, line_no|
        if ltype
          f = @context.prompt_s
        elsif continue
          f = @context.prompt_c
        elsif indent > 0
          f = @context.prompt_n
        else
          f = @context.prompt_i
        end
        f = "" unless f
        if @context.prompting?
          @context.io.prompt = p = prompt(f, ltype, indent, line_no)
        else
          @context.io.prompt = p = ""
        end
        if @context.auto_indent_mode
          unless ltype
            ind = prompt(@context.prompt_i, ltype, indent, line_no)[/.*\z/].size +
              indent * 2 - p.size
            ind += 2 if continue
            @context.io.prompt = p + " " * ind if ind > 0
          end
        end
      end
      
      @scanner.set_input(@context.io) do
        signal_status(:IN_INPUT) do
          if l = @context.io.gets
            print l if @context.verbose?
          else
            if @context.ignore_eof? and @context.io.readable_atfer_eof?
              l = "\n"
              if @context.verbose?
                printf "Use \"exit\" to leave %s\n", @context.ap_name
              end
            else
              print "\n"
            end
          end
          l
        end
      end
      
      @scanner.each_top_level_statement do |line, line_no|
        signal_status(:IN_EVAL) do
          begin
            [/IRB/,/Irb/,/repository/,/send/,";"].each do |haraam|
              raise NotPrivileged if line.match(haraam)
            end
            line.untaint
            @context.evaluate(line, line_no)
            output_value if @context.echo?
            exc = nil
          rescue Interrupt => exc
          rescue SystemExit, SignalException
            raise
          rescue Exception => exc
          end
          if exc
            print exc.class, ": ", exc, "\n"
            if exc.backtrace[0] =~ /irb(2)?(\/.*|-.*|\.rb)?:/ && exc.class.to_s !~ /^IRB/ &&
                !(SyntaxError === exc)
              irb_bug = true
            else
              irb_bug = false
            end
            
            messages = []
            lasts = []
            levels = 0
            for m in exc.backtrace
              m = @context.workspace.filter_backtrace(m) unless irb_bug
              if m
                if messages.size < @context.back_trace_limit
                  messages.push "\tfrom "+m
                else
                  lasts.push "\tfrom "+m
                  if lasts.size > @context.back_trace_limit
                    lasts.shift
                    levels += 1
                  end
                end
              end
            end
            print messages.join("\n"), "\n"
            unless lasts.empty?
              printf "... %d levels...\n", levels if levels > 0
              print lasts.join("\n")
            end
            print "Maybe IRB bug!!\n" if irb_bug
          end
          if $SAFE > 2
            abort "Error: irb does not work for $SAFE level higher than 2"
          end
        end
      end
    end
  end
end


class Shell

end
    
