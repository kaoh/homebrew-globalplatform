require "open3"

class Globalplatform < Formula
  desc "C library + command-line for Open- / GlobalPlatform smart cards"
  homepage "https://kaoh.github.io/globalplatform/"
  url "https://github.com/kaoh/globalplatform.git", tag: "2.4.2"
  head "https://github.com/kaoh/globalplatform.git", branch: "master"

  bottle do
    root_url "https://github.com/kaoh/homebrew-globalplatform/releases/download/2.4.2-b0"
    rebuild 1
    sha256 cellar: :any,                 arm64_tahoe:   "1604951bc8265c8b1fc91fd6aae2218ae58b9b45afb03daf02f0526616d62ada"
    sha256 cellar: :any,                 arm64_sequoia: "0ea8d73a2d7fc0a40db85ae9e707c577fa67fe0c425640daec4dd9ccb31ee706"
    sha256 cellar: :any,                 arm64_sonoma:  "a76cef9020902ef94297eee89e1baaf81cf514ac62e0b9403ada29bc09cefb28"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "7200650cc63cf00180851b1156dae168304f6b14e8b56107de3b1652ae194d5e"
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
