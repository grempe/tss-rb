require 'thor'

module TSS
  class CLI < Thor
    desc 'version', 'tss version'

    long_desc <<-LONGDESC
      Display the current version of TSS
    LONGDESC

    def version
      say("TSS #{TSS::VERSION}")
    end
  end
end
