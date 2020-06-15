# Summary

This is a [Homebrew Tap](https://docs.brew.sh/Taps) for the [GlobalPlatform](https://github.com/kaoh/globalplatform) C library and GPShell command line shell.

# How do I install these formulae?

`brew install kaoh/globalplatform/<formula>`

Or `brew tap kaoh/globalplatform` and then `brew install <formula>`.

# Creating Bottles

The blog on https://jonathanchang.org/blog/maintain-your-own-homebrew-repository-with-binary-bottles/ describes how to create bottles for own taps.

## Bintray

The account https://bintray.com/kaoh/bottles-globalplatform is used.

## Environment

### Linux

A docker instances can be used for running the bottling command.

~~~
docker rm brew
docker pull homebrew/brew
docker run -it --name=brew homebrew/brew
~~~

### MacOS

You need a Mac or a VirtualBox with MacOS. The VirtualBox must be reached by scp on the host port 2222.

## Bottling

The `test-bot` is used for creating the bottle inside the started environment.

~~~
# Deletes the tap, necessary if the same Docker instance is used for build retries, otherwise the updated remote is not used, a git pull might also be sufficient to get the updates
brew untap kaoh/globalplatform
brew test-bot --root-url=https://dl.bintray.com/kaoh/bottles-globalplatform --bintray-org=kaoh --tap=kaoh/globalplatform kaoh/globalplatform/globalplatform
~~~

## Uploading Bottles

The created bottle files (`.bottle.tar.gz` and `.json`)  must be collected. The naming should be identical, i.e. use the same revision of 0 (if not explicitly intended). `bottle.<revision>.tar.gz`. For revision 0 `<revision>.` is empty.

### Linux

    docker cp brew:/home/linuxbrew/. .

### MacOS VirtualBox

    scp -P2222 user@localhost:\*.{json,tar.gz} .

## Upload

   brew pr-upload --bintray-org=kaoh --root-url=https://dl.bintray.com/kaoh/bottles-globalplatform

This command also updates the formulae with a `bottle do` section.

## Push Updated Formulae

```
cd /home/linuxbrew/.linuxbrew/Homebrew/Library/Taps/kaoh/homebrew-globalplatform
git push
```

# Formulae Documentation

* [Formula-Cookbook](https://docs.brew.sh/Formula-Cookbook)
* [Formula](https://rubydoc.brew.sh/Formula)
