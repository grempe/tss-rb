# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tss/version'

Gem::Specification.new do |spec|
  spec.name          = 'tss'
  spec.version       = TSS::VERSION
  spec.authors       = ['Glenn Rempe']
  spec.email         = ['glenn@rempe.us']

  cert = File.expand_path('~/.gem-certs/gem-private_key_grempe.pem')
  if File.exist?(cert)
    spec.signing_key = cert
    spec.cert_chain = ['certs/gem-public_cert_grempe.pem']
  end

  spec.summary = <<-EOF
    A Ruby gem implementing Threshold Secret Sharing. This code can be
    used in your Ruby applications or as a simple command line (CLI)
    executable for splitting and reconstructing secrets.
  EOF

  spec.description = <<-EOF
    Threshold Secret Sharing (TSS) provides a way to generate N shares
    from a value, so that any M of those shares can be used to
    reconstruct the original value, but any M-1 shares provide no
    information about that value. This method can provide shared access
    control on key material and other secrets that must be strongly
    protected.

    This gem implements a Threshold Secret Sharing method based on
    polynomial interpolation in GF(256) and a format for the storage and
    transmission of shares.

    This implementation follows the specification in the document:

    http://tools.ietf.org/html/draft-mcgrew-tss-03
  EOF

  spec.homepage      = 'https://github.com/grempe/tss-rb'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   << 'tss'
  spec.require_paths = ['lib']

  spec.add_dependency 'dry-types', '~> 0.7'
  spec.add_dependency 'binary_struct', '~> 2.1'
  spec.add_dependency 'thor', '~> 0.19'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 11.1'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'coveralls'
end
