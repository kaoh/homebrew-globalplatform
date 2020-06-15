class Globalplatform < Formula
  desc "C library + command-line for Open- / GlobalPlatform smart cards"
  homepage "https://kaoh.github.io/globalplatform/"
  head "https://github.com/kaoh/globalplatform.git"
  url "https://github.com/kaoh/globalplatform.git", :tag => "2.0.0-b1"
  version "2.0.0-b1"

  depends_on "cmake" => :build
  depends_on "cmocka" => :build
  depends_on "doxygen" => :build
  depends_on "pandoc" => :build
  depends_on "pkg-config" => :build
  depends_on "openssl@1.1"
  depends_on "pcsc-lite"

  depends_on "zlib" unless OS.mac?

  uses_from_macos "zlib"

  def install
    system "cmake", ".", "-DTESTING=ON", "-DDEBUG=ON", *std_cmake_args
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
    system "#{bin}/gpshell", "test-script.txt"
  end
end
