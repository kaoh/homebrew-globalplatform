require "open3"

class Globalplatform < Formula
  desc "C library + command-line for Open- / GlobalPlatform smart cards"
  homepage "https://kaoh.github.io/globalplatform/"
  url "https://github.com/kaoh/globalplatform.git", tag: "2.4.2"
  head "https://github.com/kaoh/globalplatform.git", branch: "master"

  bottle do
    root_url "https://github.com/kaoh/homebrew-globalplatform/releases/download/2.4.2_1-b1"
    rebuild 2
    sha256 cellar: :any,                 arm64_tahoe:   "c88d6b42a824d3a662c3b34aab9fd3b5c5625563a0f8c922023a25290d5b72ce"
    sha256 cellar: :any,                 arm64_sequoia: "bdc6aba013f47726956f950c82267831ca25af28a5645f422e8c89753d6bb340"
    sha256 cellar: :any,                 arm64_sonoma:  "428f8bd4c8f84745ac5bafe694eb6ef098f76fcc9fd1b7e538f5269a3316f76e"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "04529df316aae0bfde068f9a4fea1303cc053601df745acf1284abeb94e2b94f"
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
