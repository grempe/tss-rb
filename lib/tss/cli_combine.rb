require 'thor'

# Command Line Interface (CLI)
# See also, `bin/tss` executable.
module TSS
  class CLI < Thor
    include Thor::Actions

    method_option :input_file, :aliases => '-I', :banner => 'input_file', :type => :string, :desc => 'A filename to read shares from'
    method_option :output_file, :aliases => '-O', :banner => 'output_file', :type => :string, :desc => 'A filename to write the recovered secret to'

    desc 'combine', 'Enter shares to recover a split secret'

    long_desc <<-LONGDESC
      `tss combine` will take as input a number of shares that were generated using the `tss split` command.

      You can enter shares one by one, or from a text file of shares. If the
      shares are successfully combined to recover a secret, the secret and
      some metadata will be written to STDOUT or a file.

      Optional Params:

      input_file :
      Provide the path to a file containing shares. Any lines in the file not
      beginning with `tss~` and matching the pattern expected for shares will be
      ignored. Leading and trailing whitespace or any other text will be ignored
      as long as the shares are each on a line by themselves.

      output_file :
      Provide the path to a file where you would like to write any recovered
      secret, instead of to STDOUT. When this option is provided the output file
      will contain only the secret itself. Some metadata, including the hash digest
      of the secret, will be written to STDOUT. Running `sha1sum` or `sha256sum`
      on the output file should provide a digest matching that of the secret
      when it was originally split.

      Example w/ options:

      $ tss combine -I shares.txt -O secret.txt
    LONGDESC

    def combine
      shares = []

      # read and process shares from a file
      if options[:input_file].present?
        if File.exist?(options[:input_file])
          file = File.open(options[:input_file], 'r')
          while !file.eof?
             line = file.readline.strip

             if line.present? && line.start_with?('tss~') && line.match(Util::HUMAN_SHARE_RE)
               shares << line
             end
          end
        else
          say("ERROR : Filename '#{options[:input_file]}' does not exist.")
          exit(1)
        end
      end

      if options[:input_file].blank?
        say('Enter shares, one per line, and a dot (.) on a line by itself to finish :')
        last_ans = nil
        until last_ans == '.'
          last_ans = ask('share> ').strip

          if last_ans.present? && last_ans != '.' && last_ans.start_with?('tss~') && last_ans.match(Util::HUMAN_SHARE_RE)
            shares << last_ans
          end
        end
      end

      begin
        sec = TSS.combine(shares: shares)

        say('')
        say('RECOVERED SECRET METADATA')
        say('*************************')
        say("hash : #{sec[:hash]}")
        say("hash_alg : #{sec[:hash_alg]}")
        say("identifier : #{sec[:identifier]}")
        say("process_time : #{sec[:process_time]}ms")
        say("threshold : #{sec[:threshold]}")

        # Write the secret to a file or STDOUT. The hash of the file checked
        # using sha1sum or sha256sum should match the hash of the original
        # secret when it was split.
        if options[:output_file].present?
          say("secret file : [#{options[:output_file]}]")
          File.open(options[:output_file], 'w'){ |somefile| somefile.puts sec[:secret] }
        else
          say('secret :')
          say(sec[:secret])
        end
      rescue TSS::Error => e
        say("ERROR : #{e.class} : #{e.message}")
      end
    end
  end
end
