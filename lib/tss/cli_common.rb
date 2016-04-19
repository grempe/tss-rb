require 'thor'

# Command Line Interface (CLI)
# See also, `bin/tss` executable.
module TSS
  class CLI < Thor

    class_option :verbose, :type => :boolean, :aliases => '-v', :desc => 'Display additional logging output'

    no_commands do
      def exit_if_binary!(str)
        str.each_byte { |c|
          # OK, 9 (TAB), 10 (CR), 13 (LF), >=32 for normal ASCII
          # Usage of anything other than 10, 13, and 32-126 ASCII decimal codes
          # looks as though contents are binary and not standard text.
          if c < 9 || (c > 10 && c < 13) || (c > 13 && c < 32) || c == 127
            err("STDIN secret appears to contain binary data.")
            exit(1)
          end
        }

        unless ['UTF-8', 'US-ASCII'].include?(str.encoding.name)
          err("STDIN secret has a non UTF-8 or US-ASCII encoding.")
          exit(1)
        end
      end

      def log(str)
        say_status(:log, "#{Time.now.utc.iso8601} : #{str}", :white) if options[:verbose]
      end

      def err(str)
        say_status(:error, "#{Time.now.utc.iso8601} : #{str}", :red)
      end
    end

  end
end
