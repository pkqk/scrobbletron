require 'net/http'
require 'digest'

$lastfm = {
  :user => 'pkqk',
  :password => 'nufink'
}
$audioscrobbler = "http://post.audioscrobbler.com"

class Scrobbler
  def handshake
    @timestamp = Time.now.utc.to_i
    params = {
      'hs' => 'true',
      'p' => '1.2',
      'c' => 'tst',
      'v' => '1.0',
    }.merge(
      'u' => $lastfm[:user],
      'a' => auth($lastfm[:password],@timestamp),
      't' => @timestamp
    )
    qs = params.collect { |kv| kv.join('=') }.join('&')
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