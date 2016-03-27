# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tss/version'

Gem::Specification.new do |spec|
  spec.name          = "tss"
  spec.version       = Tss::VERSION
  spec.authors       = ["Glenn Rempe"]
  spec.email         = ["glenn@rempe.us"]

  spec.summary       = %q{A Ruby implmentation of Threshold Secret Sharing as defined in IETF Internet-Draft draft-mcgrew-tss-03.txt}

  spec.description   = <<-EOF
    Threshold Secret Sharing (TSS) provides a way to generate N shares
    from a value, so that any M of those shares can be used to
    reconstruct the original value, but any M-1 shares provide no
    information about that value. This method can provide shared access
    control on key material and other secrets that must be strongly
    protected.

    This note defines a threshold secret sharing method based on
    polynomial interpolation in GF(256) and a format for the storage and
    transmission of shares.

    http://tools.ietf.org/html/draft-mcgrew-tss-03
  EOF

  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pry", "~> 0.10"
end
