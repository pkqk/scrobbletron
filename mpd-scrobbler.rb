require 'rubygems'
require 'librmpd'

config = {
  :host => 'localhost',
  :port => 6600
}

class MpdScrobbler
  def run
    @mpd = MPD.new
    @mpd.register_callback(method(:time_callback), MPD::TIME_CALLBACK)
    @mpd.connect(true);
  end
  
  def time_callback(*args)
    puts "time callback", args.inspect
  end
  
  def wait_for_mpd_thread
    # assuming mpd thread is the only other one
    Thread.list.reject { |t| t == Thread.current }.first.join
  rescue Interrupt
  end
  
  def stop
    @mpd.disconnect
    exit
  end
end

player = MpdScrobbler.new
trap('TERM') { puts "term called"; player.stop }
player.run
player.wait_for_mpd_thread