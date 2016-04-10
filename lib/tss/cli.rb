require 'thor'
require 'tss'

module TSS
  class CLI < Thor
    desc "split SECRET", "split SECRET"
    def split(secret)
      puts "split #{secret}!"
    end

    desc "combine SHARES", "combine SHARES"
    def combine(arg)
      puts "combine #{arg}"
    end
  end
end
