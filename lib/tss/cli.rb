require 'thor'
require 'tss'

module TSS
  class CLI < Thor
    desc "split SECRET", "split SECRET"
    def split(secret)
      puts TSS.split(secret: secret, format: 'human')
    end

    desc "combine SHARES", "combine SHARES"
    def combine(arg)
      puts "combine #{arg}"
    end
  end
end
