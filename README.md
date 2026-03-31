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

Consult your distribution for any other steps, e.g., to enable `pcsc-lite` as a service if this was forgotten by the package maintainer and is not included here already.

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

## Prepare a Release

The upstream source tag is still set manually in the formula. Update the `url ... tag:` value in `Formula/globalplatform.rb` to the already existing tag from the `kaoh/globalplatform` repository and commit that change.

Example:

~~~ruby
url "https://github.com/kaoh/globalplatform.git", tag: "2.4.2"
~~~

If the Homebrew package should supersede an earlier package without changing the upstream source tag, use a Homebrew package revision when starting the workflow, e.g. `2.4.2_1`.

## Build Bottles and Release

The release workflow is run manually in GitHub Actions from a branch of this repository. It builds bottles on Linux and Apple Silicon macOS, validates source builds on Intel macOS, merges the bottle hashes into the formula, commits the updated formula, creates the tag and creates a GitHub release.

Open the `release bottles` workflow in GitHub Actions and start it with:

- `package_version`: `2.4.2` for a normal release or `2.4.2_1` for `revision 1`
- `release_tag`: optional GitHub tag/release name and bottle `root_url` tag; defaults to `package_version`
- `prerelease`: keep the default `true` for the first run

The workflow validates that the base part of `package_version` matches the manually set upstream tag in `Formula/globalplatform.rb`. For example, `package_version: 2.4.2_1` requires `tag: "2.4.2"` in the formula.

If you want to test bottling without changing the Homebrew package version, keep `package_version` at the real package version and use a different `release_tag`, e.g.:

- `package_version`: `2.4.2`
- `release_tag`: `2.4.2-b1`
- `prerelease`: `true`

This creates a separate GitHub prerelease and bottle `root_url` while keeping the Homebrew package version at `2.4.2`.

For this kind of bottling smoke test, run the workflow from a temporary branch. The workflow commits the resulting bottle `root_url` back into the branch it was started from.

## Finalize the Release

After the workflow has completed successfully:

1. Review the created GitHub release and the generated bottle assets.
2. If everything is correct, edit the GitHub release and remove the pre-release flag.

## Notes

There are GitHub runners for macOS and Linux that are building the bottles. The Intel macOS runners are kept for source-build validation only. Homebrew `test-bot` currently skips Intel Sequoia/Tahoe bottle creation when dependencies are not bottled on those exact platforms.

## Formulae Documentation

* [Formula-Cookbook](https://docs.brew.sh/Formula-Cookbook)
* [Formula](https://rubydoc.brew.sh/Formula)

## Troubleshot Compilation

In case the compilation with `brew test-bot` gives errors in can be helpful to get an interactive shell where the
created build directory under `/tmp` is not deleted. Use the interactive mode in this case, analyze the error and try to fix the sources or build configuration.

    brew install --verbose --build-bottle kaoh/globalplatform/globalplatform --interactive
