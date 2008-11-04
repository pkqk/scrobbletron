#!/usr/bin/env ruby
require 'rubygems'
require 'librmpd'

require 'scrobbler'

class MpdScrobbler

  def initialize(opts={})
    @host = opts['hostname'] || 'localhost'
    @port = opts['port'] || 6600
    @user = opts['user'] || raise(ArgumentError, "You must supply your last.fm username")
    @pass = opts['password'] || raise(ArgumentError, "You must supply your last.fm password")
    @verbose = opts['verbose']
    @mpd = MPD.new(@host, @port)
    @scrobbler = Scrobbler.new(@user, @pass)
    @current_song = nil
    @scrobble_song = false
  end

  def run
    @scrobbler.handshake
    @mpd.register_callback(method(:song_change), MPD::CURRENT_SONG_CALLBACK)
    @mpd.register_callback(method(:time_step), MPD::TIME_CALLBACK)
    @mpd.connect(true);
  end

  def song_change(song)
    if @mpd.current_song != @current_song
      @current_song = @mpd.current_song
      @started_playing = Time.now.to_i
      scrobble(*@scrobble_song) if @scrobble_song
      @scrobble_song = false
      now_playing(@current_song) if @current_song
    end
  end

  def time_step(time,total)
    return if total == 0 || @current_song.nil?
    $stdout.write "\r%#{total.to_s.size}s/#{total}" % time
    $stdout.flush
    unless total < 30
      if @current_song.time == total.to_s && (time > 240 || time.to_f/total.to_f > 0.5)
        @scrobble_song = [@current_song, @started_playing] 
      end
    end
  end

  def scrobble(song, timestamp)
    puts "\nscrobble #{fmt_song(song)}"
    puts @scrobbler.scrobble(song, timestamp)
  end

  def now_playing(song)
    puts "\nNow Playing: #{fmt_song(song)}"
    puts @scrobbler.now_playing(song)
  end

  def fmt_song(song)
    "#{song.artist} - #{song.album} - #{song.title} (#{song.track})"
  end

  def wait_for_mpd_thread
    # assuming mpd thread is the only other one
    Thread.list.reject { |t| t == Thread.current }.last.join
  rescue Interrupt
  end
  
  def stop
    @mpd.disconnect
    exit
  end
  
  def check_loop
    @mpd.connect unless @mpd.connected?
  end
end

