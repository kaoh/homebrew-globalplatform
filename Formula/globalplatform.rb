require "open3"

class Globalplatform < Formula
  desc "C library + command-line for Open- / GlobalPlatform smart cards"
  homepage "https://kaoh.github.io/globalplatform/"
  url "https://github.com/kaoh/globalplatform.git", tag: "2.4.2"
  revision 1
  head "https://github.com/kaoh/globalplatform.git", branch: "master"

  bottle do
    root_url "https://github.com/kaoh/homebrew-globalplatform/releases/download/2.4.2_1"
    sha256 cellar: :any,                 arm64_tahoe:   "b5bb1078195d3db9b4efe76bd2ef8b10d4f9166cb5fc7d2ca6faacab606a0aa8"
    sha256 cellar: :any,                 arm64_sequoia: "d2d87bbd578d4b913b63ded47e86295c88b0ee913a90606ea94a13ce48d33018"
    sha256 cellar: :any,                 arm64_sonoma:  "be4cb5a14c6b782d5e2186173a0f2afaa8dccd79bb75cbb68269d5e6ce618ce3"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "c514614bc0e48639704a67a8763d178593f4ef4627bcb77c533c95869e7fb004"
  end

  depends_on "cmake" => :build
  depends_on "cmocka" => :build
  depends_on "doxygen" => :build
  depends_on "ghostscript" => :build
  depends_on "graphviz" => :build
  depends_on "groff" => :build
  depends_on "pandoc" => :build
  depends_on "pkg-config" => :build
  depends_on "openssl@3"

  on_linux do
    depends_on "pcsc-lite"
    # Homebrew Linux linkage checking now attributes libz to zlib-ng-compat.
    depends_on "zlib-ng-compat"
  end

  def install
    system "cmake", ".", "-DTESTING=ON", *std_cmake_args
    system "make", "install"
    system "make", "test"
    system "make", "doc"
    system "make", "install", "MANDIR=#{man}"
    if OS.mac?
      rpath = lib.to_s
      MachO::Tools.add_rpath (bin/"gpshell").to_s, rpath
      MachO::Tools.add_rpath (lib/"libgppcscconnectionplugin.1.dylib").to_s, rpath
    end
    resign_macos_binaries if OS.mac?
  end

  test do
    (testpath/"test-script.txt").write <<~EOS
      enable_trace
      establish_context
      release_context
    EOS
    oe, _status = Open3.capture2e("#{bin}/gpshell", "test-script.txt")
    puts oe
    assert_match(/0x8010001D/, oe)
  end

  private

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
