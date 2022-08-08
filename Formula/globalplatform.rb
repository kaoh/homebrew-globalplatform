require "open3"

class Globalplatform < Formula
  desc "C library + command-line for Open- / GlobalPlatform smart cards"
  homepage "https://kaoh.github.io/globalplatform/"
  url "https://github.com/kaoh/globalplatform.git", tag: "2.3.1"
  head "https://github.com/kaoh/globalplatform.git", branch: "master"

  bottle do
    root_url "https://github.com/kaoh/homebrew-globalplatform/releases/download/2.3.1"
    sha256 cellar: :any,                 catalina:     "bdd6a6218ba726ee7dc630a50da1781751bc857a1cfa766d8c63e58713c5c1fa"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "e2611aeca3d02f3052c1715e8e71ff9c9764be95eb9c0d8f3fcf65cf0424bb95"
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
    oe, _status = Open3.capture2e("#{bin}/gpshell", "test-script.txt")
    puts oe
    assert_match(/0x8010001D/, oe)
  end
end
