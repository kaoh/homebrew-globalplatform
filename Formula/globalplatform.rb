require "open3"

class Globalplatform < Formula
  desc "C library + command-line for Open- / GlobalPlatform smart cards"
  homepage "https://kaoh.github.io/globalplatform/"
  url "https://github.com/kaoh/globalplatform.git", tag: "3.0.0"
  revision 2
  head "https://github.com/kaoh/globalplatform.git", branch: "master"

  bottle do
    root_url "https://github.com/kaoh/homebrew-globalplatform/releases/download/3.0.0_2"
    sha256 cellar: :any, arm64_tahoe:   "558f7f8876f7a69a9ffc335fbf1f0dec19a8212bad9a4703d468d1104ea7f331"
    sha256 cellar: :any, arm64_sequoia: "e61dcd56a75554c9cf7c72ad1f62a1421c0dcb82caf3ec9fe561adcd85446538"
    sha256 cellar: :any, arm64_sonoma:  "8cacf6e31fcbbfd4d9309f15bc03969f5857eed2053b412e40ffe675807720d9"
    sha256 cellar: :any, x86_64_linux:  "e7ce7d52c78463a77f6e0dd5f54fbf1ea67880255d93eb3848266f644a6f0fd4"
  end

  depends_on "cmake" => :build
  depends_on "cmocka" => :build
  depends_on "pandoc" => :build
  depends_on "pkgconf" => :build
  depends_on "openssl@3"

  on_linux do
    # Homebrew's OpenSSL bottle requires a newer glibc than Ubuntu 22.04.
    depends_on "glibc"
    # Homebrew Linux linkage checking now attributes libz to zlib-ng-compat.
    depends_on "zlib-ng-compat"
  end

  def install
    cmake_args = ["-DTESTING=ON", *std_cmake_args]
    if OS.linux?
      system_pkg_config = "/usr/bin/pkg-config"
      # Homebrew's build environment has no distribution pkg-config paths.
      # Use the host search path for PC/SC while retaining Homebrew's
      # PKG_CONFIG_PATH entries for formula dependencies.
      system_pkg_config_libdir = Utils.safe_popen_read(
        { "PKG_CONFIG_LIBDIR" => nil, "PKG_CONFIG_PATH" => nil },
        system_pkg_config, "--variable=pc_path", "pkg-config"
      ).strip
      ENV["PKG_CONFIG_LIBDIR"] = system_pkg_config_libdir
      homebrew_pkg_config_paths = ENV.fetch("PKG_CONFIG_PATH", "").split(File::PATH_SEPARATOR)
      ENV["PKG_CONFIG_PATH"] = homebrew_pkg_config_paths.grep_v(%r{(?:^|/)pcsc-lite(?:/|$)}).join(File::PATH_SEPARATOR)
      begin
        Utils.safe_popen_read(
          { "PKG_CONFIG_LIBDIR" => system_pkg_config_libdir },
          system_pkg_config, "--exists", "libpcsclite"
        )
      rescue ErrorDuringExecution
        odie "Install the distribution PC/SC development package, including libpcsclite.pc."
      end
      system_pcsc_library = Pathname.new(
        Utils.safe_popen_read(
          { "PKG_CONFIG_LIBDIR" => system_pkg_config_libdir },
          system_pkg_config, "--variable=libdir", "libpcsclite"
        ).strip,
      )/"libpcsclite.so"
      odie "The distribution PC/SC development library is missing." unless system_pcsc_library.exist?
      homebrew_glibc_lib = formula_opt_lib("glibc")
      inreplace "globalplatform/cmake_modules/FindPCSC.cmake",
                "PKG_CHECK_MODULES(PCSC libpcsclite)",
                "PKG_CHECK_MODULES(PCSC NO_CMAKE_PATH NO_CMAKE_ENVIRONMENT_PATH libpcsclite)"
      inreplace "globalplatform/cmake_modules/FindPCSC.cmake",
                "INCLUDE(FindPackageHandleStandardArgs)",
                "set(PCSC_LIBRARIES \"#{system_pcsc_library}\")\n\nINCLUDE(FindPackageHandleStandardArgs)"
      ENV.append "CFLAGS", "-isystem/usr/include/PCSC"
      cmake_args << "-DCMAKE_BUILD_RPATH=#{homebrew_glibc_lib};#{HOMEBREW_PREFIX}/lib;#{system_pcsc_library.dirname}"
      cmake_args << "-DCMAKE_INSTALL_RPATH=#{homebrew_glibc_lib};#{HOMEBREW_PREFIX}/lib;" \
                    "#{system_pcsc_library.dirname}"
      cmake_args << "-DPKG_CONFIG_EXECUTABLE=#{system_pkg_config}"
    end

    system "cmake", ".", *cmake_args
    system "make", "install"
    system "make", "test"
    system "make", "install", "MANDIR=#{man}"
    install_linux_pcsc_launchers if OS.linux?
    if OS.mac?
      rpath = lib.to_s
      MachO::Tools.add_rpath (bin/"gpshell").to_s, rpath
      MachO::Tools.add_rpath (bin/"gpshell3").to_s, rpath
      MachO::Tools.add_rpath (lib/"libgppcscconnectionplugin.1.dylib").to_s, rpath
    end
    resign_macos_binaries if OS.mac?
  end

  def caveats
    return unless OS.linux?

    <<~EOS
      GPShell uses the distribution's PC/SC service and reader drivers on Linux.
      Do not link Homebrew's pcsc-lite while using this formula. If it was
      installed by an older formula version, run: brew unlink pcsc-lite

      On Debian/Ubuntu, install and enable the distribution service with:
        sudo apt install pcscd libpcsclite1 libccid
        sudo systemctl enable --now pcscd.socket

      Source builds also require libpcsclite-dev and pkg-config.
    EOS
  end

  test do
    oe, status = Open3.capture2e("#{bin}/gpshell3", "--help")
    puts oe
    assert_predicate status, :success?
    assert_match(/gpshell3/, oe)
  end

  private

  def install_linux_pcsc_launchers
    %w[gpshell gpshell3].each do |name|
      executable = bin/name
      libexec.install executable
      executable.write <<~SH
        #!/bin/sh
        set -eu

        pcsc_library=""
        for candidate in "${PCSCLITE_LIBRARY:-}" \\
          /usr/lib/x86_64-linux-gnu/libpcsclite.so.1 \\
          /lib/x86_64-linux-gnu/libpcsclite.so.1 \\
          /usr/lib/aarch64-linux-gnu/libpcsclite.so.1 \\
          /lib/aarch64-linux-gnu/libpcsclite.so.1 \\
          /usr/lib64/libpcsclite.so.1 \\
          /lib64/libpcsclite.so.1 \\
          /usr/lib/libpcsclite.so.1 \\
          /lib/libpcsclite.so.1; do
          if [ -r "$candidate" ]; then
            pcsc_library="$candidate"
            break
          fi
        done

        if [ -z "$pcsc_library" ]; then
          echo "gpshell requires the distribution libpcsclite.so.1 library." >&2
          exit 127
        fi

        pcsc_library_dir="${pcsc_library%/*}"
        exec "#{HOMEBREW_PREFIX}/lib/ld.so" \\
          --library-path "#{formula_opt_lib("glibc")}:#{HOMEBREW_PREFIX}/lib:$pcsc_library_dir" \\
          "#{libexec/name}" "$@"
      SH
      executable.chmod 0755
    end
  end

  def resign_macos_binaries
    targets = Dir[lib/"**/*.{dylib,so,bundle}", bin/"*"]
              .select { |path| File.file?(path) }
              .map { |path| Pathname(path).realpath.to_s }
              .uniq

    targets.each do |path|
      system "/usr/bin/codesign", "--force", "--sign", "-", path
    end
  end
end
