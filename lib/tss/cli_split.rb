require 'thor'

module TSS
  class CLI < Thor
    include Thor::Actions

    method_option :threshold, :aliases => '-t', :banner => 'threshold', :type => :numeric, :desc => '# of shares, of total, required to reconstruct a secret'
    method_option :num_shares, :aliases => '-n', :banner => 'num_shares', :type => :numeric, :desc => '# of shares total that will be generated'
    method_option :identifier, :aliases => '-i', :banner => 'identifier', :type => :string, :desc => 'A unique identifier string, 0-16 Bytes, [a-zA-Z0-9.-_]'
    method_option :hash_alg, :aliases => '-h', :banner => 'hash_alg', :type => :string, :desc => 'A hash type for verification, NONE, SHA1, SHA256'
    method_option :format, :aliases => '-f', :banner => 'format', :type => :string, :default => 'HUMAN', :desc => 'Share output format, BINARY or HUMAN'
    method_option :padding, :type => :boolean, :default => true, :desc => 'Whether to apply PKCS#7 padding to the secret'
    method_option :input_file, :aliases => '-I', :banner => 'input_file', :type => :string, :desc => 'A filename to read the secret from'
    method_option :output_file, :aliases => '-O', :banner => 'output_file', :type => :string, :desc => 'A filename to write the shares to'

    desc 'split', 'Split a secret into shares that can be used to re-create the secret'

    long_desc <<-LONGDESC
      `tss split` will generate a set of Threshold Secret Sharing shares from
      a SECRET provided. A secret to be split can be provided using one of three
      different input methods; STDIN, a path to a file, or when prompted
      for it interactively. In all cases the secret should be UTF-8 or
      US-ASCII encoded text and be no larger than #{TSS::MAX_UNPADDED_SECRET_SIZE}
      bytes.

      Optional Params:

      num_shares :
      The number of total shares that will be generated.

      threshold  :
      The threshold is the number of shares required to
      recreate a secret. This is always a subset of the total
      shares.

      identifier :
      A unique identifier string that will be attached
      to each share. It can be 0-16 Bytes long and use the
      characters [a-zA-Z0-9.-_]

      hash_alg :
      One of NONE, SHA1, SHA256. The algorithm to use for a one-way hash of the secret that will be split along with the secret.

      padding/no-padding :
      Whether to apply PKCS#7 padding to secret. By default padding is applied. Turning this off may be helpful if you need to interoperate with a third party library.

      format :
      Whether to output the shares as a binary octet string (RTSS), or as more human friendly URL safe Base 64 encoded text with some metadata.

      input_file :
      Provide the path to a file containing UTF-8 or US-ASCII text, the contents of which will be used as the secret.

      output_file :
      Provide the path to a file where you would like to write the shares, one per line, instead of to STDOUT.

      Example w/ options:

      $ tss split -t 3 -n 6 -i abc123 -h SHA256 -f HUMAN

      Enter your secret:

      secret >  my secret

      tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEB113xpF37jGHm5QGhXKD8mgK2897MIQkSWri6ksNnAODn0efXznuBsSUnhlDIqQFU
      tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEC4tZegQrC3z6-02er3FZaWMadtlvxPb1EI_FNjG0dFrcdEDj4V7Cmcw___SesJHHP
      tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEDWPKPVjJaITosPGAMhvCgxCBB9uptl2h5UPngnw71V7Z9T-pnxiLKIfgUbRqyBrv-
      tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEExY3ti8ckAIQC02OKCrpEVVnUmyg3NXO9oG3PNw3PlgbbKdFRi9gBCNN_tjkhT3An
      tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEFf6k8XP-8_oCQPGQtUBy-yb8I25mrn6aA02ViJG4n1we7dgPOGkptWiSUJgQ_bboW
      tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEGSiKTeaiFrd_ICgIn0OoYC3sjnhyWgxLWqiyVOsBdwVBBt9zhg4FKmA5MXXNb4MqN

    LONGDESC

    # rubocop:disable CyclomaticComplexity
    def split
      log('Starting split')
      log('options : ' + options.inspect)
      args = {}

      # There are three ways to pass in the secret. STDIN, by specifying
      # `--input-file`, and after being prompted and entering your secret
      # line by line.

      # STDIN
      # Usage : echo 'foo bar baz' | bundle exec bin/tss split
      unless STDIN.tty?
        secret = $stdin.read
        exit_if_binary!(secret)
      end

      # Read from an Input File
      if STDIN.tty? && options[:input_file].present?
        log("Input file specified : #{options[:input_file]}")

        if File.exist?(options[:input_file])
          log("Input file found : #{options[:input_file]}")
          secret = File.open(options[:input_file], 'r'){ |file| file.read }
          exit_if_binary!(secret)
        else
          err("Filename '#{options[:input_file]}' does not exist.")
          exit(1)
        end
      end

      # Enter a secret in response to a prompt.
      if STDIN.tty? && options[:input_file].blank?
        say('Enter your secret, enter a dot (.) on a line by itself to finish :')
        last_ans = nil
        secret = []

        while last_ans != '.'
          last_ans = ask('secret > ')
          secret << last_ans unless last_ans == '.'
        end

        # Strip whitespace from the leading and trailing edge of the secret.
        # Separate each line of the secret with newline, and add a trailing
        # newline so the hash of a secret when it is created will match
        # the hash of a file output when recombinging shares.
        secret = secret.join("\n").strip + "\n"
        exit_if_binary!(secret)
      end

      args[:secret]        = secret
      args[:threshold]     = options[:threshold]     if options[:threshold]
      args[:num_shares]    = options[:num_shares]    if options[:num_shares]
      args[:identifier]    = options[:identifier]    if options[:identifier]
      args[:hash_alg]      = options[:hash_alg]      if options[:hash_alg]
      args[:format]        = options[:format]        if options[:format]
      args[:padding]       = options[:padding]

      begin
        log("Calling : TSS.split(#{args.inspect})")
        shares = TSS.split(args)

        if options[:output_file].present?
          file_header  = "# THRESHOLD SECRET SHARING SHARES\n"
          file_header << "# #{Time.now.utc.iso8601}\n"
          file_header << "# https://github.com/grempe/tss-rb\n"
          file_header << "\n\n"

          File.open(options[:output_file], 'w') do |somefile|
            somefile.puts file_header + shares.join("\n")
          end
          log("Process complete : Output file written : #{options[:output_file]}")
        else
          $stdout.puts shares.join("\n")
          log('Process complete')
        end
      rescue TSS::Error => e
        err("#{e.class} : #{e.message}")
      end
    end
    # rubocop:enable CyclomaticComplexity
  end
end
