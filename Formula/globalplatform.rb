require "open3"

class Globalplatform < Formula
  desc "C library + command-line for Open- / GlobalPlatform smart cards"
  homepage "https://kaoh.github.io/globalplatform/"
  url "https://github.com/kaoh/globalplatform.git", tag: "2.4.2"
  head "https://github.com/kaoh/globalplatform.git", branch: "master"

  bottle do
    root_url "https://github.com/kaoh/homebrew-globalplatform/releases/download/2.4.2"
    sha256 cellar: :any,                 monterey:     "541e26dcbd362a082a9a115557f0c15e468abad0196e3080026349f7d48a52db"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "1e3523c6a7bbc4fb9bb64dfe76227a290a6871a33be380f129b128e1a7b2a129"
  end

  depends_on "cmake" => :build
  depends_on "cmocka" => :build
  depends_on "doxygen" => :build
  depends_on "ghostscript" => :build
  depends_on "graphviz" => :build
  depends_on "groff" => :build
  depends_on "pandoc" => :build
  depends_on "pkg-config" => :build
  depends_on "openssl@3.0"

  depends_on "pcsc-lite" unless OS.mac?
  depends_on "zlib" unless OS.mac?

  uses_from_macos "zlib"

  def install
    system "cmake", ".", "-DTESTING=ON", *std_cmake_args
    system "make", "install"
    system "make", "test"
    system "make", "doc"
    system "make", "install", "MANDIR=#{man}"
    on_macos do
      rpath = lib.to_s
      MachO::Tools.add_rpath (bin/"gpshell").to_s,                     rpath
      MachO::Tools.add_rpath (lib/"libgppcscconnectionplugin.1.dylib").to_s, rpath
    end
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
