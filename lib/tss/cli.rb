require 'thor'
require 'tss'

module TSS
  class CLI < Thor
    desc "split SECRET", "split SECRET"
    def split(secret)
      TSS.split(secret: secret).each do |share|
        h = TSS::Util.extract_share_header(share)
        identifier = h[:identifier].delete("\x00")
        threshold  = h[:threshold]
        puts "tss-v1-#{identifier}-#{threshold}-" + Base64.urlsafe_encode64(share)
      end
    end

    desc "combine SHARES", "combine SHARES"
    def combine(arg)
      puts "combine #{arg}"
    end
  end
end
