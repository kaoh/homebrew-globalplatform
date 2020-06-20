# Summary

This is a [Homebrew Tap](https://docs.brew.sh/Taps) for the [GlobalPlatform](https://github.com/kaoh/globalplatform) C library and GPShell command line shell.

# Installation

`brew install kaoh/globalplatform/globalplatform`

Or `brew tap kaoh/globalplatform` and then `brew install globalplatform`.

For Linux also look at the instructions at https://docs.brew.sh/Homebrew-on-Linux

## Linux `pcsc-lite`

### Install `pcsc-lite`

The Homebrew version of `pcsc-lite` is not a fully functional version. It is missing the USB drivers and is also not started as a system service.

The distribution's version of `pcscd` should be installed:

Ubuntu/Debian:

    apt-get install pcscd

Fedora:

    sudo dnf install ccid pcsc-lite
    sudo systemctl enable pcscd
    sudo systemctl start pcscd

RedHat:

    yum install pcsc-lite pcsc-lite-ccid pcsc-lite-libs

Arch Linux:

        pacman -S ccid    
        systemctl enable pcsclite
        systemctl start pcsclite

Consult your distribution for any other steps, e.g. to enable `pcsc-lite` as a service if this was forgotten by the package maintainer and is not included here already.

### Remove Homebrew's Version of `pcsc-lite`

If the version of `pcsc-lite` does not match the version of your system you might
get:

> establish_context failed with error 0x8010001D (Service not available.)

In this case the Homebrew's version must be unlinked if there is no chance to upgrade your distribution's version. The background of this error is a change in the internal protocol version e.g. between versions 1.9.0 and 1.8.x.

To check the version compare the versions with:

~~~
sudo $(brew --prefix pcsc-lite)/sbin/pcscd --version
sudo pcscd --version
~~~

Under Linux the Homebrew version of `pcsc-lite` must be unlinked:

    brew remove --ignore-dependencies pcsc-lite

__NOTE:__ This will remove the version, in case other package are requiring it they will also fallback to the distribution's version. If `pcsc-lite` is reinstalled this step must be repeated if there still is an internal protocol version mismatch.

# Developer Information

## Tagging GlobalPlatform

The formulae is referencing a tag version.

~~~
git tag 2.0.0-b1
git push origin 2.0.0-b1
~~~

It might be necessary to delete and recreate this tag during the release of a new beta version in a beta formulae:

~~~
git tag -d 2.0.0-b1
git push --delete origin 2.0.0-b1
~~~  

## Creating Bottles

The blog on https://jonathanchang.org/blog/maintain-your-own-homebrew-repository-with-binary-bottles/ describes how to create bottles for own taps.

### Bintray

The account https://bintray.com/kaoh/bottles-globalplatform is used. A repository `globalplatform` and a package `globalplatform` have been created.

### Environment

#### Linux

A docker instances can be used for running the bottling command.

~~~
docker rm brew
docker pull homebrew/brew
docker run -it --name=brew homebrew/brew
~~~

#### MacOS

You need a Mac or a VirtualBox with MacOS. The VirtualBox must be reached by scp on the host port 2222. Open a terminal in the user directory.

### Bottling

The `test-bot` is used for creating the bottle inside the started environment.

~~~
# Deletes the tap, necessary if the same Docker instance is used for build retries, otherwise the updated remote is not used, a git pull might also be sufficient to get the updates
brew untap kaoh/globalplatform
brew test-bot --root-url=https://dl.bintray.com/kaoh/bottles-globalplatform --bintray-org=kaoh --tap=kaoh/globalplatform kaoh/globalplatform/globalplatform
~~~

__NOTE__: If the GlobalPlatform tag had been deleted and recreated with the same name the cache of Homebrew must be cleared. A clean docker image can be started or the cache can be deleted without

    rm -r $(brew --cache)/globalplatform--git

### Uploading Bottles

The created bottle files (`.bottle.tar.gz` and `.json`)  must be collected. The naming should be identical, i.e. use the same revision of 0 (if not explicitly intended). `bottle.<revision>.tar.gz`. For revision 0 `<revision>.` is empty. Remove the revision if necessary from the `tar.gz` and the `json`.  In the `json` file also remove the `revision` attribute if necessary.

#### Linux

    docker cp brew:/home/linuxbrew/. .

#### MacOS VirtualBox

    scp -P2222 user@localhost:\*.{json,tar.gz} .

__NOTE:__ Take here instead of of `user` the proper MacOS username.

### Upload

__NOTE:__ `HOMEBREW_BINTRAY_USER` and `HOMEBREW_BINTRAY_KEY` must be set in the environment before this can be executed. Look into "Edit Profile" ->  "API Key".

   brew pr-upload --bintray-org=kaoh --root-url=https://dl.bintray.com/kaoh/bottles-globalplatform

This command also updates the formulae with a `bottle do` section.

### Push Updated Formulae

```
cd /home/linuxbrew/.linuxbrew/Homebrew/Library/Taps/kaoh/homebrew-globalplatform
git push
```

## Formulae Documentation

* [Formula-Cookbook](https://docs.brew.sh/Formula-Cookbook)
* [Formula](https://rubydoc.brew.sh/Formula)

## Troubleshot Compilation

In case the compilation with `brew test-bot` gives errors in can be helpful to get an interactive shell where the
created build directory under `/tmp` is not deleted. Use the interactive mode in this case, analyze the error and try to fix the sources or build configuration.

    brew install --verbose --build-bottle kaoh/globalplatform/globalplatform --interactive
