class Emqx < Formula
  homepage "https://emqx.io"
  url "http://52.199.153.25/emqx-ce/homebrew/emqx-homebrew-v3.0.1.zip"
  sha256 "279aad37bf6eedee3e715c8790d9d6377c3cec597396f776cbcf0205dca022f0"
  version "3.0.1"

  depends_on "openssl"

  def install
    prefix.install Dir["*"]
    bin.install Dir[libexec/"/bin/emqx"]
    rm %W[#{bin}/emqx.cmd #{bin}/emqx_ctl.cmd]
  end

  plist_options :manual => "emqx"

  def plist; <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>Program</key>
        <string>#{opt_bin}/emqx</string>
        <key>RunAtLoad</key>
        <true/>
        <key>EnvironmentVariables</key>
        <dict>
          <!-- need erl in the path -->
          <key>PATH</key>
          <string>#{HOMEBREW_PREFIX}/sbin:/usr/bin:/bin:#{HOMEBREW_PREFIX}/bin</string>
          <key>CONF_ENV_FILE</key>
          <string>#{etc}/emqx.conf<string>
        </dict>
      </dict>
    </plist>
    EOS
  end

  def post_install
    system "mkdir", "-p", "#{prefix}/data/configs"
  end

  test do
    system emqx, "start"
    system emqx_ctl, "status"
    system emqx, "stop"
  end
end
