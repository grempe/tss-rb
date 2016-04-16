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
    desc 'split SECRET', 'split a SECRET String into shares'
    long_desc <<-LONGDESC
      `tss split` will generate a set of Threshold Secret
      Sharing shares from the SECRET provided. To protect
      your secret from being saved in your shell history
      you will be prompted for the single-line secret.

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
      Whether to output the shares as a binary octet string (RTSS), or the same encoded as more human friendly Base 64 text with some metadata prefixed.

      Example using all options:

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

      say('Enter your secret:')
      args[:secret]        = ask('secret > ')
      args[:threshold]     = options[:threshold]     if options[:threshold]
      args[:num_shares]    = options[:num_shares]    if options[:num_shares]
      args[:identifier]    = options[:identifier]    if options[:identifier]
      args[:hash_alg]      = options[:hash_alg]      if options[:hash_alg]
      args[:pad_blocksize] = options[:pad_blocksize] if options[:pad_blocksize]
      args[:format]        = options[:format]        if options[:format]

      begin
        shares = TSS.split(args)
        shares.each {|s| say(s) }
      rescue => e
        say('TSS ERROR : ' + e.message)
      end
    end

    desc 'combine SHARES', 'Enter min threshold # of SHARES, one at a time, to reconstruct a split secret'
    def combine
      shares = []
      last_ans = nil

      say('Enter shares, one per line, blank line or dot (.) to finish:')
      until last_ans == '.' || last_ans == ''
        last_ans = ask('share> ')
        shares << last_ans unless last_ans.blank? || last_ans == '.'
      end

      begin
        sec = TSS.combine(shares: shares)

        say('')
        say('Secret Recovered and Verified!')
        say('')
        say('identifier : ' + sec[:identifier]) if sec[:identifier].present?
        say('threshold : ' + sec[:threshold].to_s) if sec[:threshold].present?
        say('processing time (ms) : ' + sec[:processing_time_ms].to_s) if sec[:processing_time_ms].present?
        say("secret :\n" + '*'*50 + "\n" + sec[:secret] + "\n" + '*'*50 + "\n") if sec[:secret].present?
      rescue => e
        say('TSS ERROR : ' + e.message)
      end
    end
  end
end
