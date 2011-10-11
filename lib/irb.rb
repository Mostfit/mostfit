# Monkey patch IRB to provide a secure shell to power users.
require 'irb'
module IRB
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
            puts "safe_eval"
            unless File.writable?("a")
              [/IRB/,/Irb/,/repository/,/\.send/,";",/^def /, /alias/, /class/].each do |haraam|
                raise NotPrivileged if line.match(haraam)
              end
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
    alias :old :eval_input
    alias :eval_input :safe_eval_input

  end
end


