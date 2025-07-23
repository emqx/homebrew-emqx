require "securerandom"

class Emqx < Formula
  desc "MQTT broker for AI, IoT, IIoT and IoV"
  homepage "https://www.emqx.com/en/products/emqx"
  version "5.10.0"
  license "BUSL-1.1"

  if OS.mac?
    case [MacOS.version, Hardware::CPU.arch]
    when [13, :x86_64]
      # For macOS 13 (Ventura) on Intel
      url "https://github.com/emqx/emqx/releases/download/e#{version}/emqx-enterprise-#{version}-macos13-amd64.zip"
      sha256 "9ff3fdfab88ca228b4ba1cfdba786b4186e993ba7e57b52f637f582694299f11"
    when [14, :arm64]
      # For macOS 14 (Sonoma) on Apple Silicon
      url "https://github.com/emqx/emqx/releases/download/e#{version}/emqx-enterprise-#{version}-macos14-arm64.zip"
      sha256 "7bb5c543104903d966e9138b75e2c1c94e68fb4301ac69a3148dd574cb68d16a"
    when [15, :arm64]
      # For macOS 15 (Sequoia) on Apple Silicon
      url "https://github.com/emqx/emqx/releases/download/e#{version}/emqx-enterprise-#{version}-macos15-arm64.zip"
      sha256 "2d55d8cbe8e713c277fa26d7a7b7c56766a25217950eade06db0ae4aabc7a447"
    else
      # Raise an error for unsupported combinations
      odie "EMQX is not supported on macOS #{MacOS.version} and #{Hardware::CPU.arch} architecture."
    end
  else
    odie "EMQX is only available on macOS for this formula."
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

    %w[emqx.cmd emqx_ctl.cmd no_dot_erlang.boot].each do |f|
      rm bin/f
    end
    chmod "+x", prefix/"releases/#{version}/no_dot_erlang.boot"
    bin.install_symlink prefix/"releases/#{version}/no_dot_erlang.boot"
    (var/"lib/emqx").mkpath
    (var/"log/emqx").mkpath
  end

  def caveats
    <<~EOS
      EMQX Dashboard: http://localhost:18083
    EOS
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

  test do
    exec "ln", "-s", testpath, "data"
    exec bin/"emqx", "start"
    system bin/"emqx", "ctl", "status"
    system bin/"emqx", "stop"
  end
end
