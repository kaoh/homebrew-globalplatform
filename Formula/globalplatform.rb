require "open3"

class Globalplatform < Formula
  desc "C library + command-line for Open- / GlobalPlatform smart cards"
  homepage "https://kaoh.github.io/globalplatform/"
  url "https://github.com/kaoh/globalplatform.git", tag: "2.0.0-b4"
  version "2.0.0-b4"
  head "https://github.com/kaoh/globalplatform.git"

  bottle do
    root_url "https://dl.bintray.com/kaoh/bottles-globalplatform"
    cellar :any
    sha256 "8242c2d2b32eaf5a9413f5a2088878dd5dd409e83c6146260b3cf964c0a15118" => :high_sierra
    sha256 "d05945b5435035ddba6607cc6d39b038138b3136ecd04ee04ebb82c0fd16ab51" => :x86_64_linux
  end

  depends_on "cmake" => :build
  depends_on "cmocka" => :build
  depends_on "doxygen" => :build
  depends_on "ghostscript" => :build
  depends_on "graphviz" => :build
  depends_on "groff" => :build
  depends_on "pandoc" => :build
  depends_on "pkg-config" => :build
  depends_on "openssl@1.1"

  depends_on "pcsc-lite" unless OS.mac?
  depends_on "zlib" unless OS.mac?

  uses_from_macos "zlib"

  def install
    system "cmake", ".", "-DTESTING=ON", *std_cmake_args
    system "make", "install"
    system "make", "test"
    system "make", "doc"
    system "make", "install", "MANDIR=#{man}"
  end

  test do
    (testpath/"test-script.txt").write <<~EOS
      enable_trace
      establish_context
      release_context
    EOS
    system "pcscd" unless OS.mac?
    system "#{bin}/gpshell", "test-script.txt" unless OS.mac?
    if OS.mac?
      oe, _status = Open3.capture2e("#{bin}/gpshell", "test-script.txt")
      puts oe
      assert_match(/0x8010001D/, oe)
    end
  end
end
