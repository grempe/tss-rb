# TSS

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
advanced error correction schemes. These are not currently implemented.

## Status

[![Build Status](https://travis-ci.org/grempe/tss-rb.svg?branch=master)](https://travis-ci.org/grempe/tss-rb)
[![Coverage Status](https://coveralls.io/repos/github/grempe/tss-rb/badge.svg?branch=master)](https://coveralls.io/github/grempe/tss-rb?branch=master)

## WARNING : PRE-ALPHA CODE

This code is currently a work in progress and is not yet ready for production
use. The API, input and output formats, and other aspects are likely to change
before release.

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'tss'
```

And then execute:
```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install tss
```

## Usage

### Splitting a Secret

The basic usage is as follows using the arguments described below.

```ruby
shares = Splitter.new(secret, threshold, num_shares, identifier, hash_id).split
```

#### Arguments

The `secret` (required) value must be provided as a String with either
the `UTF-8` or `US-ASCII` encoding with a Byte length  `<= 65,534`. You can
test this beforehand with `'my string secret'.bytes.to_a.length`

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

#### Example Usage

```ruby
secret = 'foo bar baz'
threshold = 3
num_shares = 5
identifier = SecureRandom.hex(8)
hash_id = SecretHash::SHA256

shares = Splitter.new(secret, threshold, num_shares, identifier, hash_id).split

=> ["ebe6ecfb44e31b12\x02\x03\x00,\x01\xB3\x81HJ\xF9\bNi\xE6\xBE\xC1b\xF8\xBFl\xBB>\xAB\x91O\xDAI\x8E\xD7\xB3\x13>m[K\xE1\x12p\x8E\x1D\x9E\x17_HM\x19\bw",
 "ebe6ecfb44e31b12\x02\x03\x00,\x024\x02\x18\xD0\xE5>\xA3\x8E\x14cH\xB5r\xB7'}~\xBE\xEF\xAF\xBE\x1C\t\xAE.\x8A|\x7F\xC5\x87\x82\x99\xC9\x8AQU\x92\xE6\xD2\xAE~\xC4Q",
 "ebe6ecfb44e31b12\x02\x03\x00,\x03\xE1\xEC?\xBA~W\x9F\xC7\x90\xBC\xF3\fY\x10\x8A\x02\"\xBB\x96\x92\x90D\x8E\xDDBJF\x9A\xEFl^fi\xFAB\xBE\xF9T\xCD9\xB1>\xF1",
 "ebe6ecfb44e31b12\x02\x03\x00,\x04c+eK\xE9\xDDY\x97\x01\xCFy\e{\x98\xBC\xAA\xFC\xE6\x1Fy8\xC9]-\x82D\xC4\xE5\xAFk(w\xF1pO\xAC[0\x9C-)\xD7\x99",
 "ebe6ecfb44e31b12\x02\x03\x00,\x05\xB6\xC5B!r\xB4e\xDE\x85\x10\xC2\xA2P?\x11\xD5\xA0\xE3fD\x16\x91\xDA^\xEE\x84\xFE\x00\x85\x80\xF4\x88Q\x00\\G0\x82\x83\xBA\xE6-9"]

reconstructed_secret = Combiner.new(shares).combine
=> "foo bar baz"
```

### Combining Shares to Recreate a Secret

The basic usage is as follows using the arguments described below.

```ruby
secret = Combiner.new(shares, args).combine
```

#### Arguments

The `shares` is used when recreating the secret and must be provided as an Array
of encoded Share Byte Strings. You must provide at least as many shares as determined
by the `threshold` value set when the shares were originally created. If you
provide too few shares a `Tss::Error` exception will be raised.

The second argument expects a Hash and is set to use the following defaults:

```ruby
args = {share_selection: :strict_first_x, output: :string_utf8}
```

`share_selection:` : This option determines how the Array of incoming shares
to be re-combined should be handled. One of the following options is valid:

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

#### Secret Output Format Args

`output:` : The value for the hash key `output:` can be the Symbol `:string_utf8`
or `:array_bytes` which will return the recombined secret as either a UTF-8
String (default) or an Array of unisgned Integer Bytes.

### Exception Handling

The splitting and combining operations may raise `Tss::ArgumentError`
or `Tss::Error` exceptions and you should rescue and handle them in your code.

`Tss::ArgumentError` exceptions will generally include the ActiveModel validation
hints where appropriate.

## RTSS Data Format

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

## Performance

The amount of time it takes to split or combine secrets grows significantly as
the size of the secret and the total `num_shares` increase. Splitting a secret
with the maximum size of `2**16 - 2` (65,534) Bytes and the maximum `255` shares
may take a long time to run. Splitting a secret with more reasonable values,
for example a `32 Byte` encryption key with `16` total shares and a threshold of `8`
may only take milliseconds to run. If you will be splitting large secrets or
using large numbers of shares, you may consider running those operations in
background processes for performance.

There are some simple benchmark tests you can run with `rake bench`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake test` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file
to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub
at [https://github.com/grempe/tss-rb](https://github.com/grempe/tss-rb). This
project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Legal

### Copyright

(c) 2016 Glenn Rempe

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

## Authors

***Glenn Rempe***</br>
<glenn@rempe.us></br>
<https://www.rempe.us></br>
@grempe on Twitter</br>

## Thank You

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
