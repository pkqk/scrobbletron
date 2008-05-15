require 'rubygems'
require 'librmpd'

$config = [ 'stealthnux', 6600 ]

class MpdScrobbler
  def run
    @mpd = MPD.new(*$config)
    @current_song = nil
    @mpd.register_callback(method(:time_callback), MPD::TIME_CALLBACK)
    @mpd.connect(true);
  end
  
  def time_callback(*args)
    if @mpd.current_song != @current_song
      @current_song = @mpd.current_song
      puts "\r#{@current_song.inspect}"
    end
    $stdout.write "\r"+args.join('/')
    $stdout.flush
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
