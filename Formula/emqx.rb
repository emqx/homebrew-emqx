class Emqx < Formula
  homepage "https://emqx.io"
  url "https://repos.emqx.io/emqx-ce/homebrew/emqx-homebrew-4.3.5.zip"
  sha256 "019e1a2a704caa6a878c46d4e3a1a5241f1cbd34d236f78de8db5a9f0460e480"
  version "4.3.5"

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
