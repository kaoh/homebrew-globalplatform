require "open3"

class Globalplatform < Formula
  desc "C library + command-line for Open- / GlobalPlatform smart cards"
  homepage "https://kaoh.github.io/globalplatform/"
  url "https://github.com/kaoh/globalplatform.git", tag: "2.0.0-b3"
  head "https://github.com/kaoh/globalplatform.git"
  version "2.0.0-b3"

  bottle do
    root_url "https://dl.bintray.com/kaoh/bottles-globalplatform"
    cellar :any
    rebuild 1
    sha256 "fe453af74f89d99c4d0e909c4f6570d22c5fb49cee7b9e5ac4c020f51cb395fd" => :high_sierra
    sha256 "0cb5830f94fa88535fb1eb5f75013bbf6075a75c41663d4dc054e561d6dfea83" => :x86_64_linux
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
      oe, status = Open3.capture2e("#{bin}/gpshell", "test-script.txt")
      puts oe
      assert status.success? || (oe.include? "0x8010001D")
    end
  end
end
