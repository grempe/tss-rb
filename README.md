# TSS - Threshold Secret Sharing

[![Gem Version](https://badge.fury.io/rb/tss.svg)](https://badge.fury.io/rb/tss)
[![Build Status](https://travis-ci.org/grempe/tss-rb.svg?branch=master)](https://travis-ci.org/grempe/tss-rb)
[![Coverage Status](https://coveralls.io/repos/github/grempe/tss-rb/badge.svg?branch=master)](https://coveralls.io/github/grempe/tss-rb?branch=master)
[![Code Climate](https://codeclimate.com/github/grempe/tss-rb/badges/gpa.svg)](https://codeclimate.com/github/grempe/tss-rb)
[![Inline docs](http://inch-ci.org/github/grempe/tss-rb.svg?branch=master)](http://inch-ci.org/github/grempe/tss-rb)

Ruby Docs : [http://www.rubydoc.info/gems/tss](http://www.rubydoc.info/gems/tss)


## WARNING : BETA CODE

This code is new and has not yet been tested in production. Use at your own risk.
The share format and interface should be fairly stable now but should not be
considered fully stable until v1.0.0 is released.

## About TSS

This Ruby gem implements Threshold Secret Sharing, as specified in
the Network Working Group Internet-Draft submitted by D. McGrew
([draft-mcgrew-tss-03.txt](http://tools.ietf.org/html/draft-mcgrew-tss-03)).

Threshold Secret Sharing (TSS) provides a way to generate `N` shares
from a value, so that any `M` of those shares can be used to
reconstruct the original value, but any `M-1` shares provide no
information about that value. This method can provide shared access
control on key material and other secrets that must be strongly
protected.

This threshold secret sharing method is based on polynomial interpolation in
GF(256) and also provides a robust format for the storage and transmission
of shares.

The sharing format is Robust Threshold Secret Sharing (RTSS) as described
in the Internet-Draft. RTSS is a binary data format and a method for
ensuring that any secrets recovered are identical to the secret that was
originally shared.

This implementation supports RTSS digest types for `NONE`, `SHA1`, and
`SHA256`. `SHA256` is the recommended digest. In the RTSS scheme a digest of
the original secret is concatenated with the secret itself prior to the splitting
of the secret into shares. Later, this digest is compared with any secret recovered
by recombining shares. If the hash of the recovered secret does not match the
original hash stored in the shares the secret will not be returned. The verifier
hash for the secret is not available to shareholders prior to recombining shares.

The specification also addresses the optional implementation of a `MAGIC_NUMBER` and
advanced error correction schemes. These extras are not currently implemented.

## TL;DR

No time for docs? Here is how to get going in 10 seconds or less with the
CLI or in Ruby. The CLI defaults to using `human` shares, and Ruby defaults
to a binary octet string representation. The default is `3 out of 5` threshold
sharing.

### CLI (Human Shares)

```text
~/src$ gem install tss
Successfully installed tss-0.1.0
1 gem installed
~/src$ tss split
Enter your secret:
secret >  my deep dark secret
tss~v1~4a993275528d5ec7~3~NGE5OTMyNzU1MjhkNWVjNwIDADQBDoW7GJ66g6nQHQZVM_iUxMVEO7NHlwDaEM5FYsVwhBSfio-WF-w2gqSKRjBp6YyqTQKR
tss~v1~4a993275528d5ec7~3~NGE5OTMyNzU1MjhkNWVjNwIDADQCxKBLxPsXuW4e7xE0zKiso49aEyuMKNIhjISe7ga865KDnBBpE1iZ6ESUkaWojKE3yNbc
tss~v1~4a993275528d5ec7~3~NGE5OTMyNzU1MjhkNWVjNwIDADQDp1zQuADISueqk2UK3yNdBDh7XGlyoD2R6X9y-BCoI7iwAE02A8aj8vKO9ticeJpQMvDi
tss~v1~4a993275528d5ec7~3~NGE5OTMyNzU1MjhkNWVjNwIDADQEgzj1RJXwKbu0pa5Z5qssmoX0cz22gVg8UCc6tasiqbDNi7bq_xKUczpYuc7utwDyPxV1
tss~v1~4a993275528d5ec7~3~NGE5OTMyNzU1MjhkNWVjNwIDADQF4MRuOG4v2jIA2dpn9SDdPTLVPH9ICbeMNdzWo702YZr-F-u174yuaYxC3rPaQzuVxTNL
~/src$ tss combine
Enter shares, one per line, blank line or dot (.) to finish:
share>  tss~v1~4a993275528d5ec7~3~NGE5OTMyNzU1MjhkNWVjNwIDADQBDoW7GJ66g6nQHQZVM_iUxMVEO7NHlwDaEM5FYsVwhBSfio-WF-w2gqSKRjBp6YyqTQKR
share>  tss~v1~4a993275528d5ec7~3~NGE5OTMyNzU1MjhkNWVjNwIDADQCxKBLxPsXuW4e7xE0zKiso49aEyuMKNIhjISe7ga865KDnBBpE1iZ6ESUkaWojKE3yNbc
share>  tss~v1~4a993275528d5ec7~3~NGE5OTMyNzU1MjhkNWVjNwIDADQDp1zQuADISueqk2UK3yNdBDh7XGlyoD2R6X9y-BCoI7iwAE02A8aj8vKO9ticeJpQMvDi
share>  .

Secret Recovered and Verified!

identifier : 4a993275528d5ec7
threshold : 3
processing time (ms) : 0.64
secret :
**************************************************
my deep dark secret
**************************************************
```

### Ruby (Binary Octet Shares)

```text
~/src$ irb
irb(main):001:0> require 'tss'
=> true
irb(main):002:0> shares = TSS.split(secret: 'my deep dark secret')
=> ["ab87eb60ae14dd87\x02\x03\x004\x01\xC6+\xC8\x9F\xE4\x7F\x85\x17\xBD\xF6\xE6\xE3m\xB9\xFF\x8CGoS\x90\xB0{\xAB\x04N\xE2\x8F\xA0\xDC\x06\xC7Y\xBE\xCD?\xBDe9\xF3\xDF\xEA\xC9s\x105\xA4\xD8TZw\x9E", "ab87eb60ae14dd87\x02\x03\x004\x02T\xBB\xEF\x12\x81\xE2\xD2\x8Et\x95\x8Eg\xE6x=HD8\xAD\xE5\xF2'OdBO4vL\xF90\xA5c\x82\xE8\x11\x94\x8E\xEEV\xB3\xAFh\xB7\x80Ac\x15\xD9\xC7\x93", "ab87eb60ae14dd87\x02\x03\x004\x03\xFF\xE9\a\xE9\x00\xF8'\xB9\xAD\x02\x1A\xEF\xAB\xB2\xA7\xA7q2\x8A\x84\xFBC\v\ny\x98\x12\xA2C\x9B\xBB\xC2qY\x05e\xF6\xC5\x11\x11K\xF6:\xEA\xE8\xF8\f\x8C4\x94\xA2", "ab87eb60ae14dd87\x02\x03\x004\x04\xD4e\xB5\xD2o\x8AxJ\x96\xBB\x80o\xDCC\x12\xA0u\xE0\xB7\xACP\x82\x14\x13\x04\xD0\xE1\x82\xC4:k\\\xA8\xC1g\xA2}\"\xCF\x04x\xEC*\xB9\xC8q,\x8F\xE1\xF6\xB4", "ab87eb60ae14dd87\x02\x03\x004\x05\x7F7])\xEE\x90\x8D}O,\x14\xE7\x91\x89\x88O@\xEA\x90\xCDY\xE6P}?\a\xC7V\xCBX\xE0;\xBA\x1A\x8A\xD6\x1Fi0C\x80\xB5x\xE4\xA0\xC8C\x16\f\xA5\x85"]
irb(main):003:0> secret = TSS.combine(shares: shares)
=> {:hash_alg=>"SHA256", :identifier=>"ab87eb60ae14dd87", :num_shares_provided=>5, :num_shares_used=>3, :processing_started_at=>"2016-04-13T19:37:14Z", :processing_finished_at=>"2016-04-13T19:37:14Z", :processing_time_ms=>0.63, :secret=>"my deep dark secret", :shares_select_by=>"first", :combinations=>nil, :threshold=>3}
irb(main):004:0> puts secret[:secret]
my deep dark secret
=> nil
```

## Is it any good?

While this implementation has not had a formal security review, the cryptographic
underpinnings were carefully specified in an IETF draft document authored by a
noted cryptographer. I have reached out to individuals respected in the field
for their work in implementing cryptographic solutions to help review this code.

> I've read draft-mcgrew-tss-03 and then took a look at your code.
> Impressive! Nice docs, clean easy-to-read code. I'd use constant-time
> comparison for hashes [[resolved : 254ecab](https://github.com/grempe/tss-rb/commit/254ecab24a338872a5b05c7446213ef1ddabf4cb)],
> but apart from that I have nothing to add. Good job!
>
> -- Dmitry Chestnykh ([@dchest](https://github.com/dchest))
>
> [v0.1.0 : 4/13/2016]

All that being said, if your threat model includes a **N**ation **S**tate **A**ctor
the security of this particular code should probably not be your primary concern.

## Suggestions for Use

* Don't split large texts. Instead, split the much smaller encryption
keys that protect encrypted large texts. Supply the encrypted
files and the shares separately to recipients. Threshold secret sharing can be
very slow at splitting and recombining very large bodies of text, especially
when combined with a large number of shares. Every byte of the secret must
be processed `num_shares` times.

* Don't treat shares like encrypted data, but instead like the encryption keys
that unlock the data. Shares are keys, and need to be protected as such. There is
nothing to slow down an attacker if they have access to enough shares.

* If you send keys by email, or some other insecure channel, then your email
provider, or any entity with access to their data, now also has the keys to
your data. They just need to collect enough keys to meet the threshold.

* Use public key cryptography to encrypt secret shares with the public key of
each individual recipient. This can protect the share data from unwanted use while
in transit or at rest. Excellent choices might be
[RbNaCl](https://github.com/cryptosphere/rbnacl)
or [TweetNaCl.js](https://github.com/dchest/tweetnacl-js).

* Put careful thought into how you want to distribute shares. It often makes
sense to give individuals more than one share.

## Documentation

There is pretty extensive inline documentation. You can view the latest
auto-generated docs at [http://www.rubydoc.info/gems/tss](http://www.rubydoc.info/gems/tss)

You can check my documentation quality score at
[http://inch-ci.org/github/grempe/tss-rb](http://inch-ci.org/github/grempe/tss-rb?branch=master)

## Supported Platforms

TSS is continuously integration tested on the following Ruby VMs:

* MRI 2.1, 2.2, 2.3

It may work on others as well.

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'tss', '~> 0.1'
```

And then execute:
```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install tss
```

### Installation Security : Signed Ruby Gem

The TSS gem is cryptographically signed. To be sure the gem you install hasn’t
been tampered with you can install it using the following method:

Add my public key (if you haven’t already) as a trusted certificate

```
# Caveat: Gem certificates are trusted globally, such that adding a
# cert.pem for one gem automatically trusts all gems signed by that cert.
gem cert --add <(curl -Ls https://raw.github.com/grempe/tss-rb/master/certs/gem-public_cert_grempe.pem)
```

To install, it is possible to specify either `HighSecurity` or `MediumSecurity`
mode. Since the `tss` gem depends on one or more gems that are not cryptographically
signed you will likely need to use `MediumSecurity`. You should receive a warning
if any signed gem does not match its signature.

```
# All dependent gems must be signed and verified.
gem install tss -P MediumSecurity
```

```
# All signed dependent gems must be verified.
gem install tss -P MediumSecurity
```

```
# Same as above, except Bundler only recognizes
# the long --trust-policy flag, not the short -P
bundle --trust-policy MediumSecurity
```

You can [learn more about security and signed Ruby Gems](http://guides.rubygems.org/security/).

### Installation Security : Signed Git Commits

Most, if not all, of the commits and tags to the repository for this code are
signed with my PGP/GPG code signing key. I have uploaded my code signing public
keys to GitHub and you can now verify those signatures with the GitHub UI.
See [this list of commits](https://github.com/grempe/tss-rb/commits/master)
and look for the `Verified` tag next to each commit. You can click on that tag
for additional information.

You can also clone the repository and verify the signatures locally using your
own GnuPG installation. You can find my certificates and read about how to conduct
this verification at [https://www.rempe.us/keys/](https://www.rempe.us/keys/).

## Command Line Interface

When you install the gem a simple `tss` command-line interface (CLI)
is also installed and should be available on your PATH.

The CLI is a simple interface for splitting and combining secrets. You can
see the options available with `tss help`, `tss help split`, or `tss help combine`.

### CLI Secret Splitting

```
$ tss help split
Usage:
  tss split SECRET

Options:
  -t, [--threshold=threshold]          # # of shares, of total, required to reconstruct a secret
  -n, [--num-shares=num_shares]        # # of shares total that will be generated
  -i, [--identifier=identifier]        # A unique identifier string, 0-16 Bytes, [a-zA-Z0-9.-_]
  -h, [--hash-alg=hash_alg]            # A hash type for verification, NONE, SHA1, SHA256
  -f, [--format=format]                # Share output format, binary or human
                                       # Default: human
  -p, [--pad-blocksize=pad_blocksize]  # Block size # secrets will be left-padded to, 0-255

Description:
  `tss split` will generate a set of Threshold Secret Sharing shares from the SECRET provided. To protect your secret from being saved in
  your shell history you will be prompted for the single-line secret.

  Optional Params:

  num_shares : The number of total shares that will be generated.

  threshold : The threshold is the number of shares required to recreate a secret. This is always a subset of the total shares.

  identifier : A unique identifier string that will be attached to each share. It can be 0-16 Bytes long and use the characters
  [a-zA-Z0-9.-_]

  hash_alg : One of NONE, SHA1, SHA256. The algorithm to use for a one-way hash of the secret that will be split along with the secret.

  pad_blocksize : An Integer, 0-255, that represents a multiple to which the secret will be padded. For example if pad_blocksize is set to
  8, the secret 'abc' would be left-padded to '00000abc' (the padding char is not zero, that is just for illustration).

  format : Whether to output the shares as a binary octet string (RTSS), or the same encoded as more human friendly Base 64 text with some
  metadata prefixed.

  Example using all options:

  $ tss split -t 3 -n 6 -i abc123 -h SHA256 -p 8 -f human

  Enter your secret:

  secret > my secret

  tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEBQ-AQG3PuU4oT4qHOh2oJmu-vQwGE6O5hsGRBNtdAYauTIi7VoIdi5imWSrswDdRy
  tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADECM0OK5TSamH3nubH3FJ2EGZ4Yux4eQC-mvcYY85oOe6ae3kpvVXjuRUDU1m6sX20X
  tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEDb7yF4Vhr1JqNe2Nc8IXo98hmKAxsqC3c_Mn3r3t60NxQMC22ate51StDOM-BImch
  tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEEIXU0FajldnRtEQMLK-ZYMO2MRa0NmkBFfNAOx7olbgXLkVbP9txXMDsdokblVwke
  tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEFfYo7EcQUOpMH09Ggz_403rvy1r9_ckI_Pd_hm1tRxX8FfzEWyXMAoFCKTOfIKgMo
  tss~v1~abc123~3~YWJjMTIzAAAAAAAAAAAAAAIDADEGDSmh74Ng8WTziMGZXAm5XcpFLqDl2oP4MH24XhYf33IIg1WsPIyMAznI0DJUeLpN

```

**Example CLI Split Usage**

For security purposes you will be prompted for your secret and cannot enter it
on the command line.

```
$ tss split -i abc
Enter your secret:
secret >  abc
tss~v1~abc~3~YWJjAAAAAAAAAAAAAAAAAAIDACQB4zjuAvBL1P2AJciAHdicf6I2qxMkLGo2Hhr4dhI_v1CSKrE=
tss~v1~abc~3~YWJjAAAAAAAAAAAAAAAAAAIDACQCNAFhHSQd8nDgihYUrdM_IsMJqYZicLuk8jBS06kUJLZTU2g=
tss~v1~abc~3~YWJjAAAAAAAAAAAAAAAAAAIDACQDtlvspaxAmQJhYDTV8Ut9AM8dISVFPXIE-1A2EavU-hTBbHQ=
tss~v1~abc~3~YWJjAAAAAAAAAAAAAAAAAAIDACQE-NVr8ofyfwYVW9_2yauIT7t4Hmt9WeFNN_ADt7vpThYNeeU=
tss~v1~abc~3~YWJjAAAAAAAAAAAAAAAAAAIDACQFeo_mSg-vFHSUsf03lTPKbbdslshaFCjtPpBndbkpkLSfRvk=
```

### CLI Share Combining

**Example CLI Combine Usage**

For security purposes you will be prompted for your shares and cannot them
on the command line.

```sh
tss combine
Enter shares, one per line, blank line or dot (.) to finish:
share> tss~v1~abc~3~YWJjAAAAAAAAAAAAAAAAAAIDACQB4zjuAvBL1P2AJciAHdicf6I2qxMkLGo2Hhr4dhI_v1CSKrE=
share> tss~v1~abc~3~YWJjAAAAAAAAAAAAAAAAAAIDACQCNAFhHSQd8nDgihYUrdM_IsMJqYZicLuk8jBS06kUJLZTU2g=
share> tss~v1~abc~3~YWJjAAAAAAAAAAAAAAAAAAIDACQDtlvspaxAmQJhYDTV8Ut9AM8dISVFPXIE-1A2EavU-hTBbHQ=
share>

Secret Recovered and Verified!

identifier : abc
threshold : 3
processing time (ms) : 0.48
secret :
**************************************************
abc
**************************************************
```

## Ruby : Splitting a Secret

The basic usage is as follows using the arguments described below.

```ruby
shares = TSS.split(secret: secret,
              threshold: threshold,
              num_shares: num_shares,
              identifier: identifier,
              hash_alg: hash_alg,
              pad_blocksize: pad_blocksize)
```

### Arguments

All arguments are passed as keys in a single Hash.

The `secret` (required) value must be provided as a String with either
a `UTF-8` or `US-ASCII` encoding. The Byte length must be `<= 65,534`. You can
test this beforehand with `'my string secret'.bytes.to_a.length`. Keep in mind
that this length also includes padding and the verification hash so your
secret may need to be shorter depending on the settings you choose.

Internally, the `secret` String will be converted to and processed as an Array
of Bytes. e.g. `'foo'.bytes.to_a`

The `num_shares` and `threshold` values are Integers representing the total
number of shares desired, and how many of those shares are required to
re-create a `secret`. Both arguments must be Integers with a value
between `1-255` inclusive. They can be Strings if directly coercible to Ints.
The `num_shares` value must be greater-than-or-equal-to the `threshold` value.
If you don't pass in these options they will be set to `threshold = 3` and
`num_shares = 5` by default.

The `identifier` is a `0-16` Byte String that will be embedded in
each output share and should uniquely identify a secret. All shares output
from the same secret splitting operation will have the same `identifier`. This
value can be retrieved easily from a share header and should be assumed to be
known to shareholders. Nothing that leaks information about the secret should
be used as an `identifier`. If an `identifier` is not set, it will default
to the output of `SecureRandom.hex(8)` which is 8 random hex bytes and
16 characters long.

The `hash_alg` is a String that represents which cryptographic one-way
hash function should be embedded in shares. The hash is used to verify
that the re-combined secret is a match for the original at creation time.
The value of the hash is not available to shareholders until a secret is
successfully re-combined. The hash is calculated from the original secret
and then combined with it prior to secret splitting. This means that the hash
is protected the same way as the secret. The algorithm used is
`secret || hash(secret)`. You can use one of `NONE`, `SHA1`, or `SHA256`.

The `format` arg takes a String Enum with either `'binary'` or `'human'` values.
This instructs the output of a split to either provide an array of binary octet
strings (standard RTSS format for interoperability), or a human friendly
URL Safe Base 64 encoded version of that same binary output. The `human` format
can be easily shared in a tweet, email, or even a URL. The `human` format is
prefixed with `tss-VERSION-IDENTIFIER-THRESHOLD-` to make it easier to visually
compare shares and see if they have matching identifiers and if you have
enough shares to reach the threshold. Note, this prefix is not parsed
or used by the `tss` combiner code at all. It is only for user convenience.

The `pad_blocksize` arg takes an Integer between 0..255 inclusive. Your secret
**MUST NOT** *begin* with this character (which was chosen to make less likely).
The padding character used is `"\u001F"` `Unit Separator, decimal 31`.

Padding is applied to the nearest multiple of the number of bytes specified.
`pad_blocksize` defaults to no padding (0). For example:

```ruby
padding_blocksize: 8
(padded with zeros for illustration purposes)

# a single char, padded up to 8
'a'         -> "0000000a"

# 8 chars, no padding needed to get to 8
'aaaaaaaa'  -> "aaaaaaaa"

# 9 chars, bumps blocksize up to 16 and pads
'aaaaaaaaa' -> "0000000aaaaaaaaa"
```

Since TSS share data is essentially the same size as the original secret
(with a known size header), padding smaller secrets may help mask the size
of the secret itself from an attacker. Padding is not part of the RTSS spec
so other TSS clients won't strip off the padding and may fail when recombining
shares. If you need this level of interoperability you should probably skip
the `pad_blocksize` padding and just pad the secret yourself prior to splitting
it. You need to pad using a character other than `"\u001F"`.

If you want to do padding this way, there is a utility method you can use
to do that. This is the same method used internally.

```ruby
# Util.left_pad(byte_multiple, input_string, pad_char = "\u001F")

> Util.left_pad(16, 'abc', "0")
=> "0000000000000abc"
```

### Example Usage

```ruby
secret     = 'foo bar baz'
threshold  = 3
num_shares = 5
identifier = SecureRandom.hex(8)
hash_alg   = 'SHA256'

s = TSS.split(secret: secret, threshold: threshold, num_shares: num_shares, identifier: identifier, hash_alg: 'SHA256', pad_blocksize: 16)

=> ["c70963b2e20fccfd\x02\x03\x001\x01\x1Fg4\xDC\xAA\x96\x9D3\xCB\xFB\xF7\xB0\x91}\xCA\xB7\x0E\xB0\xF3.}O\xD0&Z\x11\xB0\xAB\xF48f#*\xBA\xB7)l\x05\xAF4\xFA\x95\x9C\xF2\x8E\xA6\xB9=",
 "c70963b2e20fccfd\x02\x03\x001\x02Y|\x1F\x1Co\x8BW\f^\xFE\xA5\x92G\xA4\xD0K\xC6@G\xDC\x02\xBF\xF1\xAE\xE7\vP\xF1*\x9C\xA5$\edM#\xB0\xEBy\a}\xA18\rBZ\x8A\xEE",
 "c70963b2e20fccfd\x02\x03\x001\x03Y\x044\xDF\xDA{\xA5P\xB5g3P\xF6\xBB{\x86\x13#\xAC3\xBB\x92\x8F`\xCF\xEE\xF1Sz{\x10\x03\xB9\xAFZ71>(=\xF2HI\xA8\x16*\xC1\x04",
 "c70963b2e20fccfd\x02\x03\x001\x04\x90\xA3\\W\xFB\xFF.\xE8&\xA3\x13N\x968\xC5\xEEg\xA1\xD8\xB6\xD9\xE9\xAAMz\xA9\xF3H\e7#\xE7\xA8\r@\xD9\\\xB8\x7F\xF3Q\x8D\x80\xCF1~\x97P",
 "c70963b2e20fccfd\x02\x03\x001\x05\x90\xDBw\x94N\x0F\xDC\xB4\xCD:\x85\x8C''n#\xB2\xC23Y`\xC4\xD4\x83RLR\xEAK\xD0\x96\xC0\n\xC6W\xCD\xDDm.\xC9\xDEd\xF1je\x0E\xDC\xBA"]

 secret = TSS.combine(shares: s)
 => {:identifier=>"c70963b2e20fccfd",
  :num_shares_provided=>5,
  :num_shares_used=>3,
  :processing_started_at=>"2016-04-10T00:58:04Z",
  :processing_finished_at=>"2016-04-10T00:58:04Z",
  :processing_time_ms=>0.37,
  :secret=>"foo bar baz",
  :shares_select_by=>"first",
  :combinations=>nil,
  :threshold=>3}
  ```

## Ruby : Combining Shares to Recreate a Secret

The basic usage is:

```ruby
secret = TSS.combine(shares: shares)
```

### Arguments

All arguments are passed as keys in a single Hash. The return value is either
a Hash (with the `:secret` key being most important and other metadata provided
for informational purposes), or an `TSS::Error` Exception if the secret could
not be created and verified with its hash.

`shares:` (required) : Must be provided as an Array of encoded Share Byte Strings.
You must provide at least `threshold` shares as specified when the secret was
split. Providing too few shares will result in a `TSS::ArgumentError` exception
being raised. There are a large number of verifications that are performed on
shares provided to make sure they are valid and consistent with each other. An
Exception will be raised if any of these tests fail.

`select_by:` : If the number of shares provided as input to the secret
reconstruction operation is greater than the threshold M, then M
of those shares are selected for use in the operation.  The method
used to select the shares can be chosen with the `select_by:` argument
which takes the following values as options:

`select_by: 'first'` : If X shares are required by the threshold and more than X
shares are provided, then the first X shares in the Array of shares provided
will be used. All others will be discarded and the operation will fail if
those selected shares cannot recreate the secret.

`select_by: 'sample'` : If X shares are required by the threshold and more than X
shares are provided, then X shares will be randomly selected from the Array
of shares provided.  All others will be discarded and the operation will
fail if those selected shares cannot recreate the secret.

`select_by: 'combinations'` : If X shares are required, and more than X shares are
provided, then all possible combinations of the threshold number of shares
will be tried to see if the secret can be recreated.

**Warning**

This `combinations` flexibility comes with a cost. All combinations of
`threshold` shares must be generated before processing. Due to the math
associated with combinations it is possible that the system would try to
generate a number of combinations that could never be generated or processed
in many times the life of the Universe. This option can only be used if the
possible combinations for the number of shares and the threshold needed to
reconstruct a secret result in a number of combinations that is small enough
to have a chance at being processed. If the number of combinations will be too
large then the an Exception will be raised before processing has started.

If the combine operation does not result in a secret being successfully
extracted, then a `TSS::Error` exception will be raised.

### Exception Handling

Initial validation of options is done when the `TSS.split` or `TSS.combine`
methods are called. If the arguments passed are of the wrong Type or value
a `Dry::Types::ConstraintError` Exception will be raised.

The splitting and combining operations may also raise `TSS::ArgumentError`
or `TSS::Error` exceptions as they are run.

All Exception messages should include hints as to what went wrong in the
`ex.messages` attribute.

## Share Data Formats

### RTSS Binary

TSS provides shares in a binary data format with the following fields:

`Identifier`. This field contains 16 octets. It identifies the secret
with which a share is associated.  All of the shares associated
with a particular secret MUST use the same value Identifier.  When
a secret is reconstructed, the Identifier fields of each of the
shares used as input MUST have the same value.  The value of the
Identifier should be chosen so that it is unique, but the details
on how it is chosen are left as an exercise for the reader. The
characters `a-zA-Z0-9.-_` are allowed in the identifier.

`Hash Algorithm Identifier`. This field contains a single octet that
indicates the hash function used in the RTSS processing, if any.
A value of `0` indicates that no hash algorithm was used, no hash
was appended to the secret, and no RTSS check should be performed
after the reconstruction of the secret.

`Threshold`. This field contains a single octet that indicates the
number of shares required to reconstruct the secret. This field
MUST be checked during the reconstruction process, and that
process MUST halt and return an error if the number of shares
available is fewer than the value indicated in this field.

`Share Length`. This field is two octets long. It contains the number
of octets in the Share Data field, represented as an unsigned
integer in network byte order.

`Share Data`. This field has a length that is a variable number of
octets. It contains the actual share data.

```
0                   1                   2                   3
0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
|                          Identifier                           |
|                                                               |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| Hash Alg. Id. |   Threshold   |         Share Length          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
:                                                               :
:                          Share Data                           :
:                                                               :
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

This code has been tested for binary compatibility with the
[seb-m/tss](https://github.com/seb-m/tss) Python implementation of TSS. There
are test cases to ensure it remains compatible.

### RTSS Human Friendly Wrapper

To make `tss` more friendly to use when sending shares to others an enhanced
version of the RTSS binary data format is provided that is more human friendly.

Shares formatted this way can easily be shared via any communication channel.

The `human` data format is simply the same RTSS binary data, URL Safe Base64
encoded, and prefixed with a String thet contains the following tilde `~`
separated elements. The `~` is used to ensure the share remains URL Safe.

```text
tss~VERSION~IDENTIFIER~THRESHOLD~BASE64_ENCODED_BINARY_SHARE
```

A typical share with this format looks like:

```text
tss~v1~abc~3~YWJjAAAAAAAAAAAAAAAAAAIDACQB10mUbJPQZ94WpgKC2kKivfnSpCHTMr6BajbwzqOrvyMCpH0=
```

## Performance

The amount of time it takes to split or combine secrets grows significantly as
the size of the secret and the total `num_shares` and `threshold` increase.
Splitting a secret with the maximum size of `2**16 - 2` (65,534) Bytes and
the maximum `255` shares may take an unreasonably long time to run. Splitting
and Combining involves at least `num_shares**secret_bytes` operations so
larger values can quickly result in huge processing time. If you need to
split large secrets into a large number of shares you should consider
running those operations in a background worker process or thread for
best performance.

A reasonable set of values seems to be what I'll call the 'rule of 64'. If you
keep the `secret <= 64 Bytes`, the `threshold <= 64`, and the `num_shares <= 64`
you can do a round-trip split and combine operation in `~250ms` on a modern
laptop. These should be very reasonable and secure max values for most use cases.

There are some simple benchmark tests to exercise things with `rake bench`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake test` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file
to [rubygems.org](https://rubygems.org).

You can run the Command Line Interface (CLI) in development
with `bundle exec bin/tss`.

### Contributing

Bug reports and pull requests are welcome on GitHub
at [https://github.com/grempe/tss-rb](https://github.com/grempe/tss-rb). This
project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Legal

### Copyright

(c) 2016 Glenn Rempe <[glenn@rempe.us](mailto:glenn@rempe.us)> ([https://www.rempe.us/](https://www.rempe.us/))

### License

The gem is available as open source under the terms of
the [MIT License](http://opensource.org/licenses/MIT).

### Warranty

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied. See the LICENSE.txt file for the
specific language governing permissions and limitations under
the License.

## Thank You!

This code is an implementation of the Threshold Secret Sharing, as specified in
the Network Working Group Internet-Draft submitted by D. McGrew
([draft-mcgrew-tss-03.txt](http://tools.ietf.org/html/draft-mcgrew-tss-03)).
This code would not have been possible without this very well designed and
documented specification. Many examples of the relevant text from the specification
have been used as comments to annotate this source code.

Great respect to Sébastien Martini ([@seb-m](https://github.com/seb-m)) for
his [seb-m/tss](https://github.com/seb-m/tss) Python implementation of TSS.
It was invaluable as a real-world reference implementation of the
TSS Internet-Draft.
