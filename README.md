# TSS - Threshold Secret Sharing

[![Build Status](https://travis-ci.org/grempe/tss-rb.svg?branch=master)](https://travis-ci.org/grempe/tss-rb)
[![Coverage Status](https://coveralls.io/repos/github/grempe/tss-rb/badge.svg?branch=master)](https://coveralls.io/github/grempe/tss-rb?branch=master)
[![Code Climate](https://codeclimate.com/github/grempe/tss-rb/badges/gpa.svg)](https://codeclimate.com/github/grempe/tss-rb)

## WARNING : PRE-ALPHA CODE

This code is currently a work in progress and is not yet ready for production
use. The API, input and output formats, and other aspects are likely to change
before release. There has been no security review of this code.

## About

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
in transit or at rest.

* Put careful thought into how you want to distribute shares. It often makes
sense to give individuals more than one share.

## Splitting a Secret

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

## Combining Shares to Recreate a Secret

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

## RTSS Binary Data Format

TSS provides shares in a binary data format with the following fields:

`Identifier`. This field contains 16 octets.  It identifies the secret
with which a share is associated.  All of the shares associated
with a particular secret MUST use the same value Identifier.  When
a secret is reconstructed, the Identifier fields of each of the
shares used as input MUST have the same value.  The value of the
Identifier should be chosen so that it is unique, but the details
on how it is chosen are left as an exercise for the reader.

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
