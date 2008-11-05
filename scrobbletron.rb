#!/usr/bin/env ruby
require 'rubygems'
require 'mpd_scrobbler'
require 'yaml'
require 'daemons'

@config = YAML.load_file('config')
@scrobbler = MpdScrobbler.new(@config)

%w(INT TERM).each { |s| trap(s) { @scrobbler.stop } }
Daemons.run_proc('scrobbletron', {:log_output => true}) do
  @scrobbler.run
  @scrobbler.wait_for_mpd_thread
end
