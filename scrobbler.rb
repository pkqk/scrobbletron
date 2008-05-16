require 'net/http'
require 'digest'

$lastfm = {
  :user => 'pkqk',
  :password => 'nufink'
}
AUDIOSCROBBLER_URL = "http://post.audioscrobbler.com"

class Scrobbler

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
    }.merge(
      'u' => @config[:user],
      'a' => auth(@config[:password],@timestamp),
      't' => @timestamp
    )
    qs = params.collect { |kv| kv.join('=') }.join('&')
    response = @net.get("/?#{qs}")
    if response.code == 200
      info = response.body.split("\n")
      code = info.shift
      if code == "OK"
        @token, @np_url, @submit_url = info
      else
        puts code
        raise SystemExit, 1
      end
    else
      puts "Handshake failed"
      raise SystemExit, response.code
    end
  end

  def now_playing
  end

  def scrobble
  end
  
  protected
  def auth(password, timestamp)
    Digest::MD5.hexdigest(Digest::MD5.hexdigest(password)+timestamp.to_s)
  end
end
