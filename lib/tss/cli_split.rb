require 'thor'

# Command Line Interface (CLI)
# See also, `bin/tss` executable.
module TSS
  class CLI < Thor
    include Thor::Actions

    method_option :threshold, :aliases => '-t', :banner => 'threshold', :type => :numeric, :desc => '# of shares, of total, required to reconstruct a secret'
    method_option :num_shares, :aliases => '-n', :banner => 'num_shares', :type => :numeric, :desc => '# of shares total that will be generated'
    method_option :identifier, :aliases => '-i', :banner => 'identifier', :type => :string, :desc => 'A unique identifier string, 0-16 Bytes, [a-zA-Z0-9.-_]'
    method_option :hash_alg, :aliases => '-h', :banner => 'hash_alg', :type => :string, :desc => 'A hash type for verification, NONE, SHA1, SHA256'
    method_option :format, :aliases => '-f', :banner => 'format', :type => :string, :default => 'human', :desc => 'Share output format, binary or human'
    method_option :pad_blocksize, :aliases => '-p', :banner => 'pad_blocksize', :type => :numeric, :desc => 'Block size # secrets will be left-padded to, 0-255'
    method_option :input_file, :aliases => '-I', :banner => 'input_file', :type => :string, :desc => 'A filename to read the secret from'
    method_option :output_file, :aliases => '-O', :banner => 'output_file', :type => :string, :desc => 'A filename to write the shares to'

    desc 'split', 'Split a secret into shares'

    long_desc <<-LONGDESC
      `tss split` will generate a set of Threshold Secret Sharing shares from
      the SECRET provided. To protect your secret from being saved in your
      shell history you will be prompted for it unless you are providing
      the secret from an external file. You can enter as many lines
      as you like within the limits of the max size for a secret.

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

      pad_blocksize :
      An Integer, 0-255, that represents a multiple to which the secret will be padded. For example if pad_blocksize is set to 8, the secret 'abc' would be left-padded to '00000abc' (the padding char is not zero, that is just for illustration).

      format :
      Whether to output the shares as a binary octet string (RTSS), or as more human friendly URL safe Base 64 encoded text with some metadata.

      input_file :
      Provide the path to a file containing UTF-8 or US-ASCII text, the contents of which will be used as the secret.

      output_file :
      Provide the path to a file where you would like to write the shares, one per line, instead of to STDOUT.

      Example w/ options:

      $ tss split -t 3 -n 6 -i abc123 -h SHA256 -p 8 -f human

      Enter your secret:

      secret >  my secret

      tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEBQ-AQG3PuU4oT4qHOh2oJmu-vQwGE6O5hsGRBNtdAYauTIi7VoIdi5imWSrswDdRy
      tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADECM0OK5TSamH3nubH3FJ2EGZ4Yux4eQC-mvcYY85oOe6ae3kpvVXjuRUDU1m6sX20X
      tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEDb7yF4Vhr1JqNe2Nc8IXo98hmKAxsqC3c_Mn3r3t60NxQMC22ate51StDOM-BImch
      tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEEIXU0FajldnRtEQMLK-ZYMO2MRa0NmkBFfNAOx7olbgXLkVbP9txXMDsdokblVwke
      tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEFfYo7EcQUOpMH09Ggz_403rvy1r9_ckI_Pd_hm1tRxX8FfzEWyXMAoFCKTOfIKgMo
      tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEGDSmh74Ng8WTziMGZXAm5XcpFLqDl2oP4MH24XhYf33IIg1WsPIyMAznI0DJUeLpN
    LONGDESC

    def split
      args = {}

      # read and process a secret from a file
      if options[:input_file].present?
        if File.exist?(options[:input_file])
          secret = File.open(options[:input_file], 'r'){ |file| file.read }
        else
          say("ERROR : Filename '#{options[:input_file]}' does not exist.")
          exit(1)
        end
      else
        # read and process a secret, line by line, ending with a (.)
        say('Enter your secret, enter a dot (.) on a line by itself to finish :')
        last_ans = nil
        secret = []

        while last_ans != '.'
          last_ans = ask('secret > ')
          secret << last_ans unless last_ans == '.'
        end

        # Strip whitespace from the leading and trailing edge
        # of the secret.
        #
        # Separate each line of the secret with newline, and
        # also add a trailing newline so the hashes of the secret
        # when split and then joined and placed in a file will
        # also match.
        secret = secret.join("\n").strip + "\n"
      end

      args[:secret]        = secret
      args[:threshold]     = options[:threshold]     if options[:threshold]
      args[:num_shares]    = options[:num_shares]    if options[:num_shares]
      args[:identifier]    = options[:identifier]    if options[:identifier]
      args[:hash_alg]      = options[:hash_alg]      if options[:hash_alg]
      args[:pad_blocksize] = options[:pad_blocksize] if options[:pad_blocksize]
      args[:format]        = options[:format]        if options[:format]

      begin
        shares = TSS.split(args)

        # write the shares to a file or STDOUT
        if options[:output_file].present?
          File.open(options[:output_file], 'w'){ |somefile| somefile.puts shares.join("\n") }
        else
          say(shares.join("\n"))
        end
      rescue TSS::Error => e
        say("ERROR : #{e.class} : #{e.message}")
      end
    end
  end
end
