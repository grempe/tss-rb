# TSS - Threshold Secret Sharing

[![Gem Version](https://badge.fury.io/rb/tss.svg)](https://badge.fury.io/rb/tss)
[![Dependency Status](https://gemnasium.com/badges/github.com/grempe/tss-rb.svg)](https://gemnasium.com/github.com/grempe/tss-rb)
[![Build Status](https://travis-ci.org/grempe/tss-rb.svg?branch=master)](https://travis-ci.org/grempe/tss-rb)
[![Coverage Status](https://coveralls.io/repos/github/grempe/tss-rb/badge.svg?branch=master)](https://coveralls.io/github/grempe/tss-rb?branch=master)
[![Code Climate](https://codeclimate.com/github/grempe/tss-rb/badges/gpa.svg)](https://codeclimate.com/github/grempe/tss-rb)

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

No time for docs? Here is how to get going in a minute, using the
command line or Ruby, with the default `3 out of 5` secret sharing.

### Command Line Interface (CLI)

```sh
$ echo 'secret unicode characters ½ ♥ 💩' | tss split -O /tmp/shares.txt
$ tss combine -I /tmp/shares.txt

RECOVERED SECRET METADATA
*************************
hash : 6d1bc4242998bc170d35d374ebdf39295b271db900de25d249563a4622f113e0
hash_alg : SHA256
identifier : 6b02cfcfc24a2b50
process_time : 0.55ms
threshold : 3
secret :
secret unicode characters ½ ♥ 💩
```

### Ruby

```ruby
$ bundle exec bin/console
[1] pry(main)> require 'tss'
=> false
[2] pry(main)> shares = TSS.split(secret: 'my deep dark secret')
=> ["tss~v1~72e84cd688bf24fc~3~NzJlODRjZDY4OGJmMjRmYwIDADQBVLUhLlOvz_VWjEge2gH7PtqTsnSCpbfmMSFX98XUp0BmQAeeOTGDL0GVeGATWjbBZvOm",
 "tss~v1~72e84cd688bf24fc~3~NzJlODRjZDY4OGJmMjRmYwIDADQCmlZ_CZSBPk6m2-0WMEmcdzCsB8lH1oDalELd9VhlFPqby08kjm9tZBtONqXucgcnuFlQ",
 "tss~v1~72e84cd688bf24fc~3~NzJlODRjZDY4OGJmMjRmYwIDADQDo5p-Q6JLgZuUNtdjyjsCKphawUx8bNhW0FYjdk7V_4RRnZpzsCzi00hLb4igNYYraY5Z",
 "tss~v1~72e84cd688bf24fc~3~NzJlODRjZDY4OGJmMjRmYwIDADQEuqHxd94BQK1V-db70VLZxdIULyVIOGDrE7w7K3SVnk0UaEMf9xJFaYpKrXical7nR9PT",
 "tss~v1~72e84cd688bf24fc~3~NzJlODRjZDY4OGJmMjRmYwIDADQFg23wPejL_3hnFOyOKyBHmHri6aBzgjhnV6jFqGIldTPePpZIyVHK3tlP9FXSLd_rlgTa"]
[3] pry(main)> secret = TSS.combine(shares: shares)
=> {:hash=>"f1b91fef6a7535a974d3644c3eac16d2c907720c981290214d5d1db7cdb724af",
 :hash_alg=>"SHA256",
 :identifier=>"72e84cd688bf24fc",
 :process_time=>0.58,
 :secret=>"my deep dark secret",
 :threshold=>3}
[4] pry(main)> puts secret[:secret]
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

## Supported Platforms

TSS is continuously integration tested on the following Ruby VMs:

* MRI 2.2.5
* MRI 2.3.1
* jruby-9.0.5.0

It may work on others as well.

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'tss', '~> 0.4'
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
gem cert --add <(curl -Ls https://raw.github.com/grempe/tss-rb/master/certs/gem-public_cert_grempe_2026.pem)
```

To install, it is possible to specify either `HighSecurity` or `MediumSecurity`
mode. Since the `tss` gem depends on one or more gems that are not cryptographically
signed you will likely need to use `MediumSecurity`. You should receive a warning
if any signed gem does not match its signature.

```
# All dependent gems must be signed and verified.
gem install tss -P HighSecurity
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

## Command Line Interface (CLI)

When you install the gem a simple `tss` command-line interface (CLI)
is also installed and should be available on your `$PATH`.

The CLI is a user interface for splitting and combining secrets. You can
see the full set of options available with `tss help`, `tss help split`,
or `tss help combine`.

### CLI Secret Splitting

A secret to be split can be provided using one of three
different input methods; `STDIN`, a path to a file, or when prompted
interactively. In all cases the secret should be `UTF-8` or
`US-ASCII` encoded text and be no larger than 65,535 Bytes
(including header and hash verification bytes).

Each method for entering a secret may have pros and cons from a security
perspective. You need to understand what threat model you want to protect
against in order to choose wisely. Here are a few examples for how to
split a secret.

**Example : `STDIN`**

Can read the secret from `STDIN` and write the split shares to a file. Be
cautioned that this method may leave command history which may contain your
secret.

```text
echo 'a secret' | tss split -O /tmp/shares.txt
```

**Example : `--input-file`**

Can read the secret from a file and write the split shares to `STDOUT`. Be
cautioned that storing the secret on a filesystem may expose you to certain
attacks since it can be hard to fully erase files once written.

```text
$ tss split -I /tmp/secret.txt
tss~v1~3f784d9d04dff796~3~M2Y3ODRkOWQwNGRmZjc5NgIDACsBvAVAo1dH3QrsYl0S30j2VVTu6dZLRe9EEk6zLtPTwZNYk-t1e4SAA41D
tss~v1~3f784d9d04dff796~3~M2Y3ODRkOWQwNGRmZjc5NgIDACsCMfy6YlI-CQrd-l93Xtw8YqOWSP5ToolKTaZyO2fPYzceaaVmB30ycdVr
tss~v1~3f784d9d04dff796~3~M2Y3ODRkOWQwNGRmZjc5NgIDACsD4IDasmAapmVFkuYPMvuavCtXiJgPZsaBHglGm4FU_U2rGZzfapRk-ZNN
tss~v1~3f784d9d04dff796~3~M2Y3ODRkOWQwNGRmZjc5NgIDACsEbId8z1yNfEkDcezJpstkYenGLhJCMRglx2c0arPDS-YuXyiiNQQ-jYlq
tss~v1~3f784d9d04dff796~3~M2Y3ODRkOWQwNGRmZjc5NgIDACsFvfscH26p0yabGVWxyuzCv2EH7nQe9VfulMgAylVY1ZybLxEbWO1oBc9M
```

**Example : `interactive`**

Can read the secret interactively from a terminal and write the split shares
to `STDOUT`. This method is more secure since the secret will not be stored
in the command shell history or in a file on a filesystem that is hard to
erase securely. It does not protect you from simple keylogger attacks though.

```text
$ tss split
Enter your secret, enter a dot (.) on a line by itself to finish :
secret >  the vault password is:
secret >  V0ulT!
secret >  .
tss~v1~546604c0b5e9138b~3~NTQ2NjA0YzBiNWU5MTM4YgIDAD8BK-9qlyxRFFQypFLwzM_tLWOv-NRziwnc6blqFP8eh8wLro4qiQwBKfI0KuuvM0u1C6th1vxsyW8vyolXQ-4=
tss~v1~546604c0b5e9138b~3~NTQ2NjA0YzBiNWU5MTM4YgIDAD8CEjeK01kAwE1wb7-wvLLlHoe6FGzhl7Hg9TCz_Npw7u0b31OpijFIKdxELfbnhvius7vGqn6KqQKqq69s4Co=
tss~v1~546604c0b5e9138b~3~NTQ2NjA0YzBiNWU5MTM4YgIDAD8DTbCFZAMwoXU2650hAw5_XJZxzNHhJrJqLPy1vARk8APzWkgP7K79AtbVn1C49HpBSP2OL-BLumaZZWbU7YI=
tss~v1~546604c0b5e9138b~3~NTQ2NjA0YzBiNWU5MTM4YgIDAD8E9eVJ83Knw3Fq1e9VaFSKdPKUAugyBqXzCsqov6etQIfEYe8Vt-ZVu3Ax7L1MWBNt-AQLN7YtczAG4QZ_7wI=
tss~v1~546604c0b5e9138b~3~NTQ2NjA0YzBiNWU5MTM4YgIDAD8FqmJGRCiXokksUc3E1-gQNuNf2lUyt6Z50wau_3m5Xmks5PSz0XngkHqgXhsTKpGCA0JDsijsYFQ1L8_H4qo=
```

### CLI Share Combining

You can use the CLI to enter shares in order to recover a secret. Of course
you will need at least the number of shares necessary as determined
by the threshold when your shares were created. The `threshold` is visible
as the third field in every `HUMAN` formatted share.

As with splitting a secret, there are also three methods of getting the shares
into the CLI. `STDIN`, a path to a file containing shares, or interactively.

Here are some simple examples of using each:

**Example : `STDIN`**

```text
$ echo 'a secret' | tss split | tss combine

RECOVERED SECRET METADATA
*************************
hash : d4ea4551e9ff2cf56303875b1901fb8608a6164260c3b20c0976c7b606a4efc0
hash_alg : SHA256
identifier : fff58c38b14734f3
process_time : 0.34ms
threshold : 3
secret :
a secret
```

**Example : `--input-file`**

```text
$ echo 'a secret' | tss split -O /tmp/shares.txt
$ tss combine -I /tmp/shares.txt

RECOVERED SECRET METADATA
*************************
hash : d4ea4551e9ff2cf56303875b1901fb8608a6164260c3b20c0976c7b606a4efc0
hash_alg : SHA256
identifier : ae2983e30e0471fe
process_time : 0.47ms
threshold : 3
secret :
a secret
```

**Example : `interactive`**

```text
$ cat /tmp/shares.txt
# THRESHOLD SECRET SHARING SHARES
# 2016-04-19T23:57:17Z
# https://github.com/grempe/tss-rb


tss~v1~ae2983e30e0471fe~3~YWUyOTgzZTMwZTA0NzFmZQIDACoBRjAH7wA0ncxJr3GliBqKxedf3bGaQH6AscuLqxtrKxxtxuC7A7a5Sqk=
tss~v1~ae2983e30e0471fe~3~YWUyOTgzZTMwZTA0NzFmZQIDACoClWVu75w-XHhoUgkbV5XaJ11stZCB5Z8HTArpv4QsIYDBpNO9DHQTbQ4=
tss~v1~ae2983e30e0471fe~3~YWUyOTgzZTMwZTA0NzFmZQIDACoDsnUaZf94pMArKZL7jmavzk9Qa6ZAvOB8e8nEAt0nyS6ga0XBucQOyGc=
tss~v1~ae2983e30e0471fe~3~YWUyOTgzZTMwZTA0NzFmZQIDACoETCWwSGLHcutzGCLb1yOkH7i6MF7j2b0wr0ZsUh6LuBmx6FkN2MbTkTc=
tss~v1~ae2983e30e0471fe~3~YWUyOTgzZTMwZTA0NzFmZQIDACoFazXEwgGBilMwY7k7DtDR9qqG7mgigMJLmIVB70eAULfQJ89xbXbONF4=

$ tss combine
Enter shares, one per line, and a dot (.) on a line by itself to finish :
share>  tss~v1~ae2983e30e0471fe~3~YWUyOTgzZTMwZTA0NzFmZQIDACoBRjAH7wA0ncxJr3GliBqKxedf3bGaQH6AscuLqxtrKxxtxuC7A7a5Sqk=
share>  tss~v1~ae2983e30e0471fe~3~YWUyOTgzZTMwZTA0NzFmZQIDACoClWVu75w-XHhoUgkbV5XaJ11stZCB5Z8HTArpv4QsIYDBpNO9DHQTbQ4=
share>  tss~v1~ae2983e30e0471fe~3~YWUyOTgzZTMwZTA0NzFmZQIDACoDsnUaZf94pMArKZL7jmavzk9Qa6ZAvOB8e8nEAt0nyS6ga0XBucQOyGc=
share>  .

RECOVERED SECRET METADATA
*************************
hash : d4ea4551e9ff2cf56303875b1901fb8608a6164260c3b20c0976c7b606a4efc0
hash_alg : SHA256
identifier : ae2983e30e0471fe
process_time : 0.7ms
threshold : 3
secret :
a secret
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
between `1-255` inclusive. The `num_shares` value must be
greater-than-or-equal-to the `threshold` value. If you don't pass in
these options they will be set to `threshold = 3` and `num_shares = 5` by default.

The `identifier` is a `1-16` Byte String that will be embedded in
each output share and should uniquely identify a secret. All shares output
from the same secret splitting operation will have the same `identifier`. This
value can be retrieved easily from a share header and should be assumed to be
known to shareholders. Nothing that leaks information about the secret should
be used as an `identifier`. If an `identifier` is not set, it will default
to the output of `SecureRandom.hex(8)` which is 8 random hex bytes (16 characters).

The `hash_alg` is a String that represents which cryptographic one-way
hash function should be embedded in shares. The hash is used to verify
that the re-combined secret is a match for the original at creation time.
The value of the hash is not available to shareholders until a secret is
successfully re-combined. The hash is calculated from the original secret
and then combined with it prior to secret splitting. This means that the hash
is protected the same way as the secret. The algorithm used is
`secret || hash(secret)`. You can use one of `NONE`, `SHA1`, or `SHA256`.

The `format` arg takes an uppercase String Enum with either `'HUMAN'` (default) or
`'BINARY'` values. This instructs the output of a split to either provide an
array of binary octet strings (a standard RTSS format for interoperability), or
a human friendly URL Safe Base 64 encoded version of that same binary output.
The `HUMAN` format can be easily shared in a tweet, email, or even a URL. The
`HUMAN` format is prefixed with `tss~VERSION~IDENTIFIER~THRESHOLD~` to make it
easier to visually compare shares and see if they have matching identifiers and
if you have enough shares to reach the threshold.

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
format     = 'HUMAN'

s = TSS.split(secret: secret, threshold: threshold, num_shares: num_shares, identifier: identifier, hash_alg: 'SHA256', pad_blocksize: 16, format: format)

=> ["tss~v1~9fdfe2516240737e~3~OWZkZmUyNTE2MjQwNzM3ZQIDADEBe1METAFZDbpq7yHIFRvxr1PjBOLRnHzDyzDGrnDvYp90jMKPLWwo3eiWiuafRaYJ",
 "tss~v1~9fdfe2516240737e~3~OWZkZmUyNTE2MjQwNzM3ZQIDADECOeQaLXYx99N2SDKutj0_smSonMdMMzeJc_CWPRT8nppHkdsUc7hW6cSw_RDcaKMF",
 "tss~v1~9fdfe2516240737e~3~OWZkZmUyNTE2MjQwNzM3ZQIDADEDXagBfmgOlQY8xXIUg0SvZ-yYgORZzeWiyjRBmsDMLwG7bLmmswSAOllamqGZ-_fb",
 "tss~v1~9fdfe2516240737e~3~OWZkZmUyNTE2MjQwNzM3ZQIDADEExmXZHYJsLzipmqYryl5SDlhJzdZxLh_2y5bM_tOOmdm9rpws3izJqHrzmCHQi5mn",
 "tss~v1~9fdfe2516240737e~3~OWZkZmUyNTE2MjQwNzM3ZQIDADEFoinCTpxTTe3jF-aR_yfC29B50fVk0M3dclIbWQe-KEJBU_6eHpAfe-cZ_5CVGM15"]

 secret = TSS.combine(shares: s)

 => {:hash=>"dbd318c1c462aee872f41109a4dfd3048871a03dedd0fe0e757ced57dad6f2d7",
 :hash_alg=>"SHA256",
 :identifier=>"9fdfe2516240737e",
 :process_time=>0.77,
 :secret=>"foo bar baz",
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

`select_by: 'FIRST'` : If X shares are required by the threshold and more than X
shares are provided, then the first X shares in the Array of shares provided
will be used. All others will be discarded and the operation will fail if
those selected shares cannot recreate the secret.

`select_by: 'SAMPLE'` : If X shares are required by the threshold and more than X
shares are provided, then X shares will be randomly selected from the Array
of shares provided.  All others will be discarded and the operation will
fail if those selected shares cannot recreate the secret.

`select_by: 'COMBINATIONS'` : If X shares are required, and more than X shares are
provided, then all possible combinations of the threshold number of shares
will be tried to see if the secret can be recreated.

**Warning**

This `COMBINATIONS` flexibility comes with a cost. All combinations of
`threshold` shares must be generated before processing. Due to the math
associated with combinations it is possible that the system would try to
generate a number of combinations that could never be generated or processed
in many times the life of the Universe. This option can only be used if the
possible combinations for the number of shares and the threshold needed to
reconstruct a secret result in a number of combinations that is small enough
to have a chance at being processed. If the number of combinations will be too
large an Exception will be raised before processing has even started. The default
maximum number of combinations that will be tried is 1,000,000.

**Fun Fact**

If 255 total shares are available, and the threshold value is 128, it would result in
`2884329411724603169044874178931143443870105850987581016304218283632259375395`
possible combinations of 128 shares that could be tried. That is *almost* as
many combinations (`2.88 * 10^75`) as there are Atoms in the Universe (`10^80`).

If the combine operation does not result in a secret being successfully
extracted, then a `TSS::Error` exception will be raised.

A great short read on this is
[On the (Small) Number of Atoms in the Universe](http://norvig.com/atoms.html)

### Exception Handling

Almost all methods in the program have strict contracts associated with them
that enforce argument presence, types, and value boundaries. This contract checking
is provided by the excellent Ruby [Contracts](https://egonschiele.github.io/contracts.ruby/) gem. If a contract violation occurs a `ParamContractError` Exception will be raised.

The splitting and combining operations may also raise the following
exception types:

`TSS::NoSecretError`, `TSS::InvalidSecretHashError`,
`TSS::ArgumentError`, `TSS::Error`

All Exceptions should include hints as to what went wrong in the
`#message` attribute.

## Share Data Formats

### RTSS Binary

TSS provides shares in a binary data format with the following fields, and
by default this binary data is wrapped in a `'HUMAN'` text format:

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

This data format has been tested for binary compatibility with the
[seb-m/tss](https://github.com/seb-m/tss) Python implementation of TSS. There
are test cases to ensure it remains compatible.

### RTSS Human Friendly Wrapper

To make `tss` friendlier to use when sending shares to others, an enhanced
text wrapper around the RTSS binary data format is provided.

Shares formatted this way can easily be shared via most any communication channel.

The `HUMAN` data format is simply the same RTSS binary data, URL Safe Base64
encoded, and prefixed with a String thet contains tilde `~` separated elements.
The `~` is used as it is compatible with the URL Safe data and the allowed
characters in the rest of the human format string.

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
best performance. For example a 64kb file split into 255 shares,
with a threshold of 255 (the max for all three settings), can take
20 minutes to split and another 20 minutes to combine using a modern CPU.

A reasonable set of values seems to be what I'll call the 'rule of 64'. If you
keep the `secret <= 64 Bytes`, the `threshold <= 64`, and the `num_shares <= 64`
you can do a round-trip split and combine operation in `~250ms`. These should
be very reasonable and secure max values for most use cases, even as part of a
web request response cycle. Remember, its recommended to split encryption keys,
not plaintext.

There are some simple benchmark tests to exercise things with `rake bench`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake test` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

You can run the Command Line Interface (CLI) in development
with `bundle exec bin/tss`.

The formal release process can be found in [RELEASE.md](https://github.com/grempe/tss-rb/blob/master/RELEASE.md)

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
