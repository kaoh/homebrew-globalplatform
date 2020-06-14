# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
class Globalplatform < Formula
  desc "Library and command shell for providing access to OpenPlatform 2.0.1' and GlobalPlatform 2.1.1 conforming smart cards and later."
  homepage "globalplatform.github.io"
  head "https://github.com/kaoh/globalplatform.git"
  version "2-beta"

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "openssl@1.1"
  depends_on "cmocka" => :build
  depends_on "pcsc-lite"

  unless OS.mac
    depends_on "zlib"
  end

  uses_from_macos "zlib"

  def install
    system "cmake", ".", "-DTESTING=ON", "-DDEBUG=O", *std_cmake_args
    system "make", "test"
    system "make", "doc"
    system "make", "install", "MANDIR=#{man}"
  end

  test do
    system "#{bin}/gpshell", "--help"
  end
end
