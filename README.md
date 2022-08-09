# Summary

This is a [Homebrew Tap](https://docs.brew.sh/Taps) for the [GlobalPlatform](https://kaoh.github.io/globalplatform/) C library and GPShell command line shell.

Please read also the [manual of GPShell]( https://github.com/kaoh/globalplatform/blob/master/gpshell/src/gpshell.1.md) if you are interested in the command line
or use the installed man page with `man gpshell` under Unix like systems.
There are several script examples available. See the [.txt files](https://github.com/kaoh/globalplatform/tree/master/gpshell) or look into the local file systems
under `(/usr/ | /home/linuxbrew/.linuxbrew/) share/doc/gpshell1/`.

Consult the [API documentation](https://kaoh.github.io/globalplatform/api/index.html) if you are planning to use this as a library.

# Installation

`brew install kaoh/globalplatform/globalplatform`

Or `brew tap kaoh/globalplatform` and then `brew install globalplatform`.

For Linux also look at the instructions at [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux)

## MacOS M1

homebrew on MacOS has problems when installing the project due to problems of the unsatisfied [GHC dependency](https://doesitarm.com/formula/ghc/).
This seems to be a requirement of the homebrew build system and as long as no upstream support is available use this workaround:

~~~shell
arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
arch -x86_64 /usr/local/bin/brew install kaoh/globalplatform/globalplatform
~~~

## Linux `pcsc-lite`

### Install `pcsc-lite`

The Homebrew version of `pcsc-lite` is not a fully functional version. It is missing the USB drivers and is also not started as a system service.

The distribution's version of `pcscd` should be installed:

Ubuntu/Debian:

~~~shell
    apt-get install pcscd
~~~

Fedora:

~~~shell
    sudo dnf install ccid pcsc-lite
    sudo systemctl enable pcscd
    sudo systemctl start pcscd
~~~

RedHat:

~~~shell
    yum install pcsc-lite pcsc-lite-ccid pcsc-lite-libs
~~~

Arch Linux:

~~~shell
        pacman -S ccid    
        systemctl enable pcsclite
        systemctl start pcsclite
~~~

Consult your distribution for any other steps, e.g. to enable `pcsc-lite` as a service if this was forgotten by the package maintainer and is not included here already.

### Remove Homebrew's Version of `pcsc-lite`

If the version of `pcsc-lite` does not match the version of your system you might
get:

> establish_context failed with error 0x8010001D (Service not available.)

In this case the Homebrew's version must be unlinked if there is no chance to upgrade your distribution's version. The background of this error is a change in the internal protocol version e.g. between versions 1.9.0 and 1.8.x.

To check the version compare the versions with:

~~~shell
sudo $(brew --prefix pcsc-lite)/sbin/pcscd --version
sudo pcscd --version
~~~

Under Linux the Homebrew version of `pcsc-lite` must be unlinked:

~~~shell
    brew remove --ignore-dependencies pcsc-lite
~~~

__NOTE:__ This will remove the version, in case other package are requiring it they will also fallback to the distribution's version. If `pcsc-lite` is reinstalled this step must be repeated if there still is an internal protocol version mismatch.

# Developer Information

## Tag GlobalPlatform

The formulae is referencing a tag version.

~~~shell
git tag 2.0.0-b1
git push origin 2.0.0-b1
~~~

It might be necessary to delete and recreate this tag during the release of a new beta version in a beta formulae:

~~~shell
git tag -d 2.0.0-b1
git push --delete origin 2.0.0-b1
~~~

## Update Code and Tag Homebrew Globalplatform

At first it is necessary to update the used tagged Globalplatform version in the formula file.

It is also occasionally necessary to update the Ruby code in the formulae and to check if in 
the meanwhile the brew build system added some breaking changes requiring to update the formulae code. Unfortunately this is happening periodically.

~~~shell
# Deletes the tap to have a clean state
brew remove globalplatform
brew untap kaoh/globalplatform
brew tap kaoh/globalplatform
~~~

~~~shell
# MacOS:
# cd /usr/local/Homebrew/Library/Taps/kaoh/homebrew-globalplatform
# Linux:
#cd /home/linuxbrew/.linuxbrew/Homebrew/Library/Taps/kaoh/homebrew-globalplatform/
# make your necessary fixes
# update the tag to the required version in the url
brew audit --strict --online globalplatform
~~~

### Push Changes

Since Homebrew has used a HTTPS URL for the checkout it will be required to use `git` instead to commit any changes:

~~~shell
git remote remove origin
git remote add git@github.com:kaoh/homebrew-globalplatform
git commit -a -m ...
git push origin master
~~~

## Creating Bottles

The blog on https://jonathanchang.org/blog/maintain-your-own-homebrew-repository-with-binary-bottles/ describes how to create bottles for own taps.

Because Bintray has shut down its service, now GitHub is used directly.

### Environment

#### Linux

A Docker instance can be used for running the bottling command.

~~~shell
docker rm brew
docker pull homebrew/ubuntu16.04
docker run -it --name=brew homebrew/ubuntu16.04
mkdir build
cd build
~~~

#### MacOS

Homebrew can be directly executed in MacOS.

__NOTE:__ For testing the installation later the Homebrew cellar and tap must be removed again to have a clean environment.

### Bottling

The `test-bot` is used for creating the bottle inside the started environment.

~~~shell
# Deletes the tap to have a clean state
brew remove globalplatform
brew untap kaoh/globalplatform
brew test-bot --root-url=https://github.com/kaoh/homebrew-globalplatform/releases/download/2.2.1 --tap=kaoh/globalplatform kaoh/globalplatform/globalplatform
~~~

Adjust the release tag at the end of the `root-url` option.

__NOTE__: If the GlobalPlatform tag had been deleted and recreated with the same name the cache of Homebrew must be cleared. A clean docker image can be started or the cache can be deleted with:

~~~shell
rm -rf $(brew --cache)/globalplatform--git
brew remove globalplatform
brew untap kaoh/globalplatform
~~~

## Updating Formulae with Bottle References

The updated formulaes from Linux and MacOS must be merged together. The git repository in the
Linux Docker container is `/home/linuxbrew/.linuxbrew/Homebrew/Library/Taps/kaoh/homebrew-globalplatform`.
Under MacOS the location is `/usr/local/Homebrew/Library/Taps/kaoh/homebrew-globalplatform`.

Example:

~~~ruby
   bottle do
     root_url "https://github.com/kaoh/homebrew-globalplatform/releases/download/2.1.0"
     sha256 cellar: :any, catalina: "23f4a097e12cacbf3a1ecc6de002bb8a6b1965ab9c93702ace2af78270f148d5"
     sha256 cellar: :any_skip_relocation, x86_64_linux: "22a961043e2c4cb62d9b92a5856fbc74c05fd0e83b838a73ffa329462719de0a"
   end
~~~

Check the correctness of the edit:

~~~shell
brew style Formula/globalplatform.rb
~~~

Formatting problems can be fixed with:

~~~shell
brew style --fix Formula/globalplatform.rb
~~~

### Uploading Bottles

The created bottle files (`.bottle.tar.gz` and `.json`)  must be collected. The naming should be identical, i.e. use the same revision of 0 (if not explicitly intended).   `bottle.<revision>.tar.gz`. For revision 0 `<revision>.` is empty. If a previous bottle of the same version exist the name will include a new revision. For beta releases it might be possible to remove the revision if necessary from the `tar.gz` and the `json`.  In the `json` file also remove the `revision` attribute if necessary.

### Tag

Push the updated formula and tag the master or working branch:

~~~shell
git commit -a -m ...
git push origin master
git tag 2.2.1
git push origin 2.2.1
~~~

Create now a new release in GitHub for the tag.

#### Linux

Copy the build bottle to the current directory:

~~~shell
docker cp brew:/home/linuxbrew/build/. .
~~~

### Upload Bottles

In the release section of this repository upload the `tar.gz` files. Replace the double `--` by just one `-`.

## Formulae Documentation

* [Formula-Cookbook](https://docs.brew.sh/Formula-Cookbook)
* [Formula](https://rubydoc.brew.sh/Formula)

## Troubleshot Compilation

In case the compilation with `brew test-bot` gives errors in can be helpful to get an interactive shell where the
created build directory under `/tmp` is not deleted. Use the interactive mode in this case, analyze the error and try to fix the sources or build configuration.

    brew install --verbose --build-bottle kaoh/globalplatform/globalplatform --interactive
