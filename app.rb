require 'sinatra'
require 'feedjira'

class Media

  def self.all
    ObjectSpace.each_object(self).to_a
  end

  def fifo
    unless File.exist?('/tmp/mplayer-control')
      `mkfifo /tmp/mplayer-control`
    end
  end

  def play(source)
    fifo
    `mplayer -slave -input file=/tmp/mplayer-control #{source}`
  end

  def self.mplayer(command)
    `echo "#{command}" > /tmp/mplayer-control`
  end
end












class Podcast < Media
  attr_accessor :name, :url, :episodes

  def initialize(name, url)
    @name = name
    @url = url
  end

  def fetch(source)
    Feedjira::Feed.fetch_and_parse source
  end

  def self.search_name(query)
    a = self.all.to_a
    a.select! { |n| n.name == query }
    a[0]
  end

  def self.spawn(name, url)
    if Podcast.search_name(name).nil?
      Podcast.new(name, url)
    end
  end

  def populate
    self.episodes = fetch(@url)
  end

end












class Radio < Media
  attr_accessor :name, :url

  def initialize(name, url)
    @name = name
    @url = url
  end
end

get '/' do
  @radio = Radio.all
  erb :index
end

post '/' do
  command = params[:command].to_s
  Media.mplayer(command)
  redirect back
end

post '/stream' do
  stream = Radio.new("Test", params[:stream].to_s)
  url = stream.url
  stream.play(url)
  redirect back
end

get '/sgu' do
  Podcast.spawn("SGU", "http://www.theskepticsguide.org/feed/sgu/")
  podcast = Podcast.search_name("SGU")
  podcast.populate
  @episodes = podcast.episodes.entries[0..9]
  erb :sgu
end

get '/rd' do
  Podcast.spawn("Reconcilable Differences", "https://www.relay.fm/rd/feed")
  podcast = Podcast.search_name("Reconcilable Differences")
  podcast.populate
  @episodes = podcast.episodes.entries[0..9]
  erb :sgu
end

