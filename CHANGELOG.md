# CHANGELOG

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
