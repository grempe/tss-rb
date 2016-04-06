# TSS - Threshold Secret Sharing

[![Build Status](https://travis-ci.org/grempe/tss-rb.svg?branch=master)](https://travis-ci.org/grempe/tss-rb)
[![Coverage Status](https://coveralls.io/repos/github/grempe/tss-rb/badge.svg?branch=master)](https://coveralls.io/github/grempe/tss-rb?branch=master)

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
gem 'tss', '~> 1.0.0'
```

And then execute:
```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install tss
```

## Guidelines for Use

* Don't split large texts. Instead, split the much smaller encryption
keys that protect encrypted large texts. Supply the encrypted
files and the shares separately to recipients. Threshold secret sharing can be
very slow at splitting and recombining very large bodies of text. Every byte must
be processed `num_shares` times.

* Don't treat shares like encrypted data, but instead like the encryption keys
that unlock the data. Shares are keys, and need to be protected as such. There is
nothing to slow down an attacker if they have access to enough shares.

* If you send keys by email, or some other insecure channel,  then your email
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
shares = Splitter.new(secret, threshold, num_shares, identifier, hash_id, opts).split
```

### Arguments

The `secret` (required) value must be provided as a String with either
the `UTF-8` or `US-ASCII` encoding with a Byte length  `<= 65,534`. You can
test this beforehand with `'my string secret'.bytes.to_a.length`. The secret
will be left-padded with the Unicode `"\u001F"` `Unit Separator, decimal 31` character
up to 32 Bytes. This padding will be removed before the secret is checked against
its RTSS hash when recombined. Your secret **MUST NOT** *begin* with this character
(which is unlikely in any case). If your secret is 32 Bytes or longer no padding will
be applied. This padding masks the size of relatively small secrets from an attacker.

Internally, the `secret` String will be converted to and processed as an Array
of Bytes. e.g. `'foo'.bytes.to_a`

The `num_shares` (required) and `threshold` (required) values are Integers
representing the total number of shares desired, and how many of those shares
are required to re-create a `secret`. Both arguments must be Integers with a value
between `1-255` inclusive. The `num_shares` must be greater-than-or-equal-to the
`threshold` value specified.

The `identifier` (required) is a `0-16` Byte String that will be embedded in
each output share and should be unique. All shares output from the same
secret splitting operation will have the same `identifier`. This value
can be retrieved from any share and should be assumed to be known to shareholders
so nothing that leaks information about the secret should be used as an `identifier`.

The `hash_id` is an Integer code that represents which cryptographic One-Way Hash function
has been embedded in the shares to allow verification that the re-constructed
secret is a match for the original at creation time. There are currently three
valid values which have been specified as constants for your convenience.
`SecretHash::SHA256` is the recommended Hash Digest to use.

```ruby
SecretHash::NONE                 // code 0
SecretHash::SHA1                 // code 1
SecretHash::SHA256               // code 2
```

The `opts` arg is a hash of optional arguments which currently accepts a single
hash key `padding` which takes a value between 0..127 inclusive.

```ruby
{ padding: 8 }

If padded with zeros for example:

'a'         -> "0000000a"
'aaaaaaaa'  -> "aaaaaaaa"
'aaaaaaaaa' -> "0000000aaaaaaaaa"

```

This will left pad the secret to the nearest multiple of Bytes specified.
Defaults to no padding (0). Padding is done with the "\u001F" character
(decimal 31 when in a Byte Array). Your secret must not begin with this
character.

Since TSS share data is essentially the same size as the original secret,
padding smaller secrets may help mask the size of the contents from an
attacker. Padding is not part of the RTSS spec so other TSS clients
won't strip off the padding and may fail when recombining. If you need
this interoperability you should probably pad the secret yourself prior
to splitting it and leave the default zero-length pad in place.

During the share combining operation the padding will be stripped off
of the secret bytes prior to verifying the secret with any RTSS hash.

### Example

```ruby
secret = 'foo bar baz'
threshold = 3
num_shares = 5
identifier = SecureRandom.hex(8)
hash_id = SecretHash::SHA256

shares = Splitter.new(secret, threshold, num_shares, identifier, hash_id).split

=> ["ca81eda2c6b80c23\x02\x03\x00A\x01T\xE5W\xB8q\x01\x1F\xE3\x85GqG\xD2\x8D\xC8\xC9C\x89\xE9\xDA\xD4\xD2\x98k.\x99\x06\x87M\xA6\x11\xE1\xCDAw\xAD\x00x\xB7vA4=\xB4}Z\xECD\xE3/C`\xF0v\xA2\xB3\xC3\x8F\xB9\xC2\x06\x12\xDB\xE4",
 "ca81eda2c6b80c23\x02\x03\x00A\x02\x9C\x7FH\xC3\xD8\x8E\xCEd\xB5\xFAD\x02\x88\xC1\xEC\x1C\xF4R\xB9\x19.\x93\x14\x17\xB2\xC5\x06N\xC2\x88\xF3\x18\x00\xB7\x1Fz\x8Av\r\xDE\x05\xF6 \xE1\x8A\xD2B\x96\x99\xC4\x18\xBFQ\x92\xE3\xCF`s:\be\xEF\x10D",
 "ca81eda2c6b80c23\x02\x03\x00A\x03\xD7\x85\x00d\xB6\x90\xCE\x98/\xA2*ZES;\xCA\xA8\xC4O\xDC\xE5'\xE3\x13\xBC>a\xBB\xAFL\x83\x83\x16%p\x16Nl\x14@66\f\\SW}\xD6\xF2\x9A\xFB\xE2L4\xBFr\xD6\x80n\x9D\xB9+9w",
 "ca81eda2c6b80c23\x02\x03\x00A\x04V\xD5\x80\xAE\xE6\xA4\xCF\xBFr\x81\x83\xA7r\x11\xE1\xFF\x85v\x17y\xBB\xB9\x97D\x11\x04=\x13\x1FR\x8D\x99\x87l_;\x01\xCA\x81\xC0\xD8\xA2\xCC\xD0\xD2\xB5{s\x9B$D\xC2\xA0\x00f!\xCC\x87\xBFJ\xCF:\xDB\x13",
 "ca81eda2c6b80c23\x02\x03\x00A\x05\x1D/\xC8\t\x88\xBA\xCFC\xE8\xD9\xED\xFF\xBF\x836)\xD9\xE0\xE1\xBCp\r`@\x1F\xFFZ\xE6r\x96\xFD\x02\x91\xFE0W\xC5\xD0\x98^\xEBb\xE0m\v0D3\xF0z\xA7\x9F\xBD\xA6:\x9Czt\xEB\xDF\x13\xFE\xF2 "]

reconstructed_secret = Combiner.new(shares).combine
=> "foo bar baz"
```

## Combining Shares to Recreate a Secret

The basic usage is as follows using the arguments described below.

```ruby
secret = Combiner.new(shares, args).combine
```

### Arguments

`shares` (required) : Must be provided as an Array of encoded Share Byte Strings.
You must provide at least `threshold` shares as specified when the secret was split.
Providing too few shares will result in a `Tss::ArgumentError` exception being raised.

Options Hash (optional) : A Hash of options.

#### Option : Share selection

`share_selection:` : This key determines how the Array of incoming shares
to be re-combined should be handled when more than `threshold` shares are
provided. One of the following `Symbol` values for this key are valid:

`:strict_first_x` : If `M` shares are required as a threshold, then the
first `M` shares in the Array of `shares` provided will be used. All other
`shares` will be discarded and the operation will fail if the selected shares
cannot recreate the secret.

`:strict_sample_x` : If `M` shares are required as a threshold, then a random
`M` shares in the Array of `shares` provided will be used. All other
`shares` will be discarded and the operation will fail if the selected shares
cannot recreate the secret.

`:any_combination` :  If `M` shares are required as a threshold, then all possible
`M` share combinations in the Array of `shares` provided will be used. The combinations
will be tried one after the other until the first one succeeds or they all fail.
This combination technique can only be used if the RTSS hash type was set to
`SHA1` or `SHA256` when the shares were created.

### Exception Handling

The splitting and combining operations may raise `Tss::ArgumentError`
or `Tss::Error` exceptions and you should rescue and handle them in your code.
Exception messages may include hints as to what went wrong.

## RTSS Binary Data Format

We use a data format with the following fields, in order:

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
you can do a round-trip split and combine operation in ~250ms on a modern
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

### Thank You

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
