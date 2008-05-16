require 'rubygems'
require 'librmpd'

$config = [ 'stealthnux', 6600 ]

class MpdScrobbler
  def run
    @mpd = MPD.new(*$config)
    @current_song = nil
    @scrobbled_song = false
    @mpd.register_callback(method(:song_change), MPD::CURRENT_SONG_CALLBACK)
    @mpd.register_callback(method(:time_step), MPD::TIME_CALLBACK)
    @mpd.connect(true);
    wait_for_mpd_thread
  end

  def song_change(song)
    if @mpd.current_song != @current_song
      @current_song = @mpd.current_song
      @scrobbled_song = false
      now_playing(@current_song)
    end
  end

  def time_step(time,total)
    return if total == 0
    $stdout.write "\r#{time}/#{total}"
    $stdout.flush
    unless total < 30
      if time > 240 || time.to_f/total.to_f > 0.5
        scrobble(@current_song) if @current_song.time == total.to_s
      end
    end
  end

  def scrobble(song)
    return if @scrobbled_song || @current_song != song
    @scrobbled_song = true
    puts "\nWould scrobble #{fmt_song(song)}"
  end

  def now_playing(song)
    puts "\nNow Playing: #{fmt_song(song)}"
  end

  def fmt_song(song)
    "#{song.artist} - #{song.album} - #{song.title}"
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

MpdScrobbler.new.run
