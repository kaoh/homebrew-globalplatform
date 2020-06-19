require "open3"

class Globalplatform < Formula
  desc "C library + command-line for Open- / GlobalPlatform smart cards"
  homepage "https://kaoh.github.io/globalplatform/"
  head "https://github.com/kaoh/globalplatform.git"
  url "https://github.com/kaoh/globalplatform.git", :tag => "2.0.0-b1"
  version "2.0.0-b1"

  bottle do
    root_url "https://dl.bintray.com/kaoh/bottles-globalplatform"
    cellar :any_skip_relocation
    sha256 "1660c01a7c943978eaf52e8d23eda2c1f7852faacc377fe793579e2fae0ec2d9" => :high_sierra
    sha256 "55f4eeac5c73e9ddd0db911180730583fa9fb13e82d8d3fc73ebc24e4bc97927" => :x86_64_linux
  end

  depends_on "cmake" => :build
  depends_on "cmocka" => :build
  depends_on "doxygen" => :build
  depends_on "pandoc" => :build
  depends_on "pkg-config" => :build
  depends_on "openssl@1.1"

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
    system "pcscd" unless OS.mac?
    system "#{bin}/gpshell", "test-script.txt" unless OS.mac?
    if OS.mac?
      oe, status = Open3.capture2e("#{bin}/gpshell", "test-script.txt")
      puts oe
      assert status.success? || (oe =~ /0x8010001D/)
    end
  end
end
