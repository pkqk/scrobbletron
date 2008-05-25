require 'net/http'
require 'digest'

$lastfm = {
  :user => 'pkqk',
  :password => 'nufink'
}
AUDIOSCROBBLER_URL = "post.audioscrobbler.com"

class Scrobbler
  class ConnectError < StandardError; end

  def initialize(config)
    @config = config
    @net = Net::HTTP.new(AUDIOSCROBBLER_URL,80)
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
    qs = params.collect { |kv| kv.join('=') }.join('&')
    response = @net.get("/?#{qs}")
    if response.code.to_i == 200
      info = response.body.split("\n")
      code = info.shift
      if code == "OK"
        @token, @np_url, @submit_url = info
        @now_playing = Net::HTTP.new(URI.parse(@np_url))
        @submit = Net::HTTP.new(URI.parse(@submit_url))
      else
        raise ConnectError, "Handshake response: #{code}" 
      end
    else
      raise ConnectError, "Handshake failed: #{response.code}"
    end
  end

  def now_playing(args)
    params = {
      's' => @token,
      'a' => args.artist,
      't' => args.title,



    }
  end

  def scrobble(args)
  end
  
  protected
  def auth(password, timestamp)
    Digest::MD5.hexdigest(Digest::MD5.hexdigest(password)+timestamp.to_s)
  end
end
