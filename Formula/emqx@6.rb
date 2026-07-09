require "securerandom"

class EmqxAT6 < Formula
  desc "MQTT broker for AI, IoT, IIoT and IoV"
  homepage "https://www.emqx.com/en/products/emqx"
  version "6.2.2"
  license "BUSL-1.1"

  if OS.mac?
    os_version_tag = ""
    sha = ""

    if Hardware::CPU.arch == :arm64 && MacOS.version >= 15
      os_version_tag = "macos15"
      sha = "8ffbde0a358f785492d78601c86764cfedf169eef8e8a86ddde3f83153884f29"
    elsif Hardware::CPU.arch == :arm64 && MacOS.version == 14
      os_version_tag = "macos14"
      sha = "d14c1198e387587703c137d818879dc66a3171f8c80a23ae3cfc0460d4a0751d"
    else
      odie <<~EOS
        EMQX #{version} is only supported on macOS 14 (Sonoma) or later
        with the arm64 (Apple Silicon) architecture using this formula.
      EOS
    end

    url "https://github.com/emqx/emqx/releases/download/#{version}/emqx-enterprise-#{version}-#{os_version_tag}-arm64.zip"
    sha256 sha
  else
    odie "This EMQX formula is only available for macOS."
  end

  depends_on "openssl@3"

  def install
    cookie = SecureRandom.hex(40)
    vars_file = buildpath/"releases/emqx_vars"
    vars_file.append_lines <<~EOS
      EMQX_LOG_DIR=#{var}/log/emqx
      EMQX_ETC_DIR=#{pkgetc}
    EOS

    emqx_conf_file = buildpath/"etc/emqx.conf"
    emqx_conf_file.append_lines <<~EOS
      node {
        data_dir = "#{var}/lib/emqx"
        cookie = "#{cookie}"
      }
    EOS

    prefix.install Dir["*"]
    etc_exclude = %w[examples lwm2m_xml]
    (prefix/"etc").children.reject { |file| etc_exclude.include?(file.basename.to_s) }.each do |file|
      pkgetc.install file unless (pkgetc/file.basename).exist?
    end

    (var/"lib/emqx").mkpath
    (var/"log/emqx").mkpath
  end

  service do
    run [opt_bin/"emqx", "foreground"]
  end

  def post_install
    # Find all executables and dynamic libraries in the installation prefix.
    # This includes your main executables in `bin` and all `.so`/`.dylib` files.
    mach_files = `find #{prefix} -type f -exec file {} + | grep "Mach-O"`.lines.map { |l| l.split(":").first }

    # Re-sign each of them with a simple ad-hoc signature.
    mach_files.each do |file|
      system "codesign", "--force", "--deep", "--sign", "-", file
    end
  end

  def caveats
    <<~EOS
      EMQX Dashboard: http://localhost:18083
    EOS
  end

  test do
    system "ln", "-s", testpath, "data"
    system bin/"emqx", "start"
    system bin/"emqx", "ctl", "broker"
    system bin/"emqx", "stop"
  end
end
