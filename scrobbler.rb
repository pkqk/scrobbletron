require 'net/http'
require 'digest'

class Scrobbler
  CONFIG = {
    :user => 'pkqk',
    :password => 'nufink'
  }

  AUDIOSCROBBLER = "post.audioscrobbler.com"
  class ConnectError < StandardError; end
  class UpdateError < StandardError; end
  class SubmitError < StandardError; end

  def initialize(config=CONFIG)
    @config = config
    @net = Net::HTTP.new(AUDIOSCROBBLER,80)
  end

  def handshake
    @timestamp = Time.now.utc.to_i
    params = {
      'hs' => 'true',
      'p' => '1.2',
      'c' => 'tst',
      'v' => '1.0',
      'u' => @config[:user],
      'a' => auth(@config[:password],@timestamp),
      't' => @timestamp
    }
    qs = encode_params(params)
    response = @net.get("/?#{qs}")
    if response.code.to_i == 200
      info = response.body.split("\n")
      code = info.shift
      if code == "OK"
        @token, @np_url, @submit_url = info
        @now_playing = URI.parse(@np_url)
        @submit = URI.parse(@submit_url)
      else
        raise ConnectError, "Handshake response: #{code}" 
      end
    else
      raise ConnectError, "Handshake failed: #{response.code}"
    end
  end

  def now_playing(song)
    params = track_params(song).merge('s' => @token)
    r = Net::HTTP.post_form(@now_playing, params)
    return r.body
  end

  def scrobble(song, played_at)
    params = {}
    track_params(song).merge('o' => 'P', 'r' => '', 'i' => played_at.to_s).collect { |k,v| params["#{k}[0]"] = v }
    params = params.merge('s' => @token)
    r = Net::HTTP.post_form(@submit, params)
    return r.body
  end
  
  protected
  
  def track_params(song)
    params = {
      'a' => song.artist,
      't' => song.title,
      'b' => song.album,
      'l' => song.time ,
      'n' => song.track || '', 
      'm' => ''
    }
  end
  def encode_params(params)
    params.collect { |kv| kv.join('=') }.join('&')
  end
  def auth(password, timestamp)
    Digest::MD5.hexdigest(Digest::MD5.hexdigest(password)+timestamp.to_s)
  end
end
