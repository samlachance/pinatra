require 'sinatra'
require 'feedjira'

class Media

  # This allows you to call all on any Class to get a list of its objects
  def self.all
    ObjectSpace.each_object(self).to_a
  end

  # In order to control mplayer in slave mode it needs a file to read changes from
  # I went ahead and just threw it in /tmp/ because it seemed like the right thing to do
  # This checks to see if that file exists and then creates it if it doesn't
  def self.fifo
    unless File.exist?('/tmp/mplayer-control')
      `mkfifo /tmp/mplayer-control`
    end
  end

  # This method creates the fifo file (if not already present) then, 
  # starts mplayer in slave mode and tells it to watch the fifo file.
  def self.play(source)
    fifo
    `mplayer -slave -input file=/tmp/mplayer-control #{source}`
    redirect to('/controls')
  end

  # This method allows you to pass in commands for mplayer. Commands can be found with the google
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

  # Fetches podcasts from a source url
  def fetch(source)
    Feedjira::Feed.fetch_and_parse source
  end

  # Searches for an object of Podcast class by name
  def self.search_name(query)
    a = self.all.to_a # the to_a is needed to perform the search
    a.select! { |n| n.name == query } # Searches each object in the arracy for the object with your name
    a[0] # Returns the object in the 0 index
  end

  # Essentially utilizes the search_name method to prevent duplicate podcasts from being created
  def self.spawn(name, url)
    if Podcast.search_name(name).nil? 
      Podcast.new(name, url) # If a podcast with that name already exists, it will return nil
    end
  end

  # This method is called when the user wants to play a podcast.
  # The podcast is downloaded into the /tmp/podcast.mp3 file and
  # and then passed into the play method. This is done to allow
  # the user to pause and seek without dropping the stream.
  def self.podcast(source)
    `wget -O /tmp/podcast.mp3 #{source}`
    play("/tmp/podcast.mp3")
  end

  # Call this method on the object to store a current list of episodes in the @episodes variable
  def populate
    self.episodes = fetch(@url)
  end
end


get '/' do
  erb :index
end

get '/controls' do
  erb :controls
end

# The controls post to the '/' directory and then redirect back to where you came from
post '/' do
  command = params[:command].to_s
  Media.mplayer(command)
  redirect to('/controls')
end

# Normal internet radio streams post to here. The stream source (which is specified in the markup)
# is then passed into the play method.
post '/stream' do
  stream = params[:stream].to_s
  Media.play(stream)
  redirect to('/controls')
end

# Podcasts post here. When a source is passed into the podcast method, the file is downloaded
# and then played locally
post '/stream-podcast' do
  source = params[:stream_podcast].to_s
  Podcast.podcast(source)
  redirect to('/controls')
end


# Below are examples of different podcasts. I wanted them to be on seperate pages because the list of episodes
# can get long. Doing it this way also allows you to fine tune how many episodes appear in the list

get '/sgu' do
  Podcast.spawn("SGU", "http://www.theskepticsguide.org/feed/sgu/") #Spawns the Podcast object
  podcast = Podcast.search_name("SGU") # Finds that object
  podcast.populate # Populates the @episodes variable
  @episodes = podcast.episodes.entries[0..29] # Pulls the first 10 episodes and then stores it for the view
  erb :podcast # Renders the view
end

get '/rd' do
  Podcast.spawn("Reconcilable Differences", "https://www.relay.fm/rd/feed")
  podcast = Podcast.search_name("Reconcilable Differences")
  podcast.populate
  @episodes = podcast.episodes.entries[0..29]
  erb :podcast
end

get '/ct' do
  Podcast.spawn("Car Talk", "http://www.npr.org/rss/podcast.php?id=510208")
  podcast = Podcast.search_name("Car Talk")
  podcast.populate
  @episodes = podcast.episodes.entries[0..9]
  erb :podcast
end

get '/rl' do
  Podcast.spawn("Radio Lab", "http://feeds.wnyc.org/radiolab?format=xml")
  podcast = Podcast.search_name("Radio Lab")
  podcast.populate
  @episodes = podcast.episodes.entries[0..9]
  erb :podcast
end

get '/htde' do
  Podcast.spawn("How to do Everything", "http://www.npr.org/rss/podcast.php?id=510303")
  podcast = Podcast.search_name("How to do Everything")
  podcast.populate
  @episodes = podcast.episodes.entries[0..9]
  erb :podcast
end

get '/tfl' do
  Podcast.spawn("The Flop House", "http://theflophouse.libsyn.com/rss")
  podcast = Podcast.search_name("The Flop House")
  podcast.populate
  @episodes = podcast.episodes.entries[0..9]
  erb :podcast
end

get '/otm' do
  Podcast.spawn("On the Media", "http://www.onthemedia.org/feeds/episodes/")
  podcast = Podcast.search_name("On the Media")
  podcast.populate
  @episodes = podcast.episodes.entries[0..9]
  erb :podcast
end
