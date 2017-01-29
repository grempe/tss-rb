# CHANGELOG

## v0.5.0 (1/28/2017)

* Breaking refactor to use automatic PKCS#7 padding on secrets w/ 16 byte block size.
* Update Copyright year
* Ruby 2.4.0 testing
* Update version of sysrandom gem
* Fixed minitest spec warning

## v0.4.2 (10/12/2016)

* Sign the gem with a new cert that expires in 10 years.
    Both old and new public certs are in the certs dir.

## v0.4.1 (9/28/2016)

* Use activesupport for blank support. Remove the extraction.
* Update sysrandom and remove the workaround needed for earlier version

## v0.4.0 (9/24/2016)

* Breaking change to force upcasing of some addition string args
* Use yard-contracts
* yardoc cleanups
* Remove int_commas utility method
* Hash w/ sha256 a,b strings in secure_compare
* Deeper Contracts integration

## v0.3.0 (9/24/2016)

* Breaking change, identifier cannot be an empty string
* Much greater coverage of functions with Contracts
* Related documentation updates

## v0.2.0 (9/23/2016)

* clone the shares object passed to TSS.combine to prevent modification
* test enhancements
* use cryptosphere/sysrandom in place of native securerandom
* integer args are no longer coercible from Strings
* Remove dry-* in favor of contracts (http://egonschiele.github.io/contracts.ruby/)
* readme fixes

## v0.1.1 (4/14/2016)

* documentation enhancements
* added two additional custom exception classes to allow rescuing from no secret recovery or invalid hash during recovery
* specify Rubies >= 2.1.0 in gemspec

## v0.1.0 (4/12/2016)

This is the initial ALPHA quality release of the tss gem.

It is for review only and should not yet be used in production.
