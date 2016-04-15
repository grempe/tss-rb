# Gem Release Process

Don't use the `bundle exec rake release` task. It is more convenient,
but it skips the process of signing the version release task.

## Run Tests

```sh
$ rake test_all
```

## Git Push

```sh
$ git push
```

Check for regressions in automated tests:

* [https://travis-ci.org/grempe/tss-rb](https://travis-ci.org/grempe/tss-rb)
* [https://coveralls.io/github/grempe/tss-rb?branch=master](https://coveralls.io/github/grempe/tss-rb?branch=master)
* [https://codeclimate.com/github/grempe/tss-rb](https://codeclimate.com/github/grempe/tss-rb)
* [http://inch-ci.org/github/grempe/tss-rb](http://inch-ci.org/github/grempe/tss-rb)

## Bump Version Number and edit CHANGELOG.md

```sh
$ vi lib/tss/version.rb
$ git add lib/tss/version.rb
$ vi CHANGELOG.md
$ git add CHANGELOG.md
```

## Local Build and Install w/ Signed Gem

The `build` step should ask for PEM passphrase to sign gem. If it does
not ask it means that the signing cert is not present.

Build:

```sh
$ rake build
Enter PEM pass phrase:
tss 0.1.1 built to pkg/tss-0.1.1.gem.
```

Install locally w/ Cert:

```sh
$ gem uninstall tss
$ rbenv rehash
$ gem install pkg/tss-0.1.1.gem -P MediumSecurity
Successfully installed tss-0.1.1
1 gem installed
```

## Git Commit Version and CHANGELOG Changes, Tag and push to Github

```sh
$ git add lib/tss/version.rb
$ git add CHANGELOG.md
$ git commit -m 'Bump version v0.1.1'
$ git tag -s v0.1.1 -m "v0.1.1" SHA1_OF_COMMIT
```

Verify last commit and last tag are GPG signed:

```
$ git tag -v v0.1.0
...
gpg: Good signature from "Glenn Rempe (Code Signing Key) <glenn@rempe.us>" [ultimate]
...
```

```
$ git log --show-signature
...
gpg: Good signature from "Glenn Rempe (Code Signing Key) <glenn@rempe.us>" [ultimate]
...
```

Push code and tags to GitHub:

```
$ git push
$ git push --tags
```

## Push gem to Rubygems.org

```sh
$ gem push pkg/tss-0.1.1.gem
```

Verify Gem Push at [https://rubygems.org/gems/tss](https://rubygems.org/gems/tss)

## Create a GitHub Release

Specify the tag we just pushed to attach release to. Copy notes from CHANGELOG.md

[https://github.com/grempe/tss-rb/releases](https://github.com/grempe/tss-rb/releases)

## Announce Release on Twitter

The normal blah, blah, blah.
