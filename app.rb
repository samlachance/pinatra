class Media

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
end

class Radio < Media
  attr_accessor :name, :url

  def initialize(name, url)
    @name = name
    @url = url
  end

  def self.all
    ObjectSpace.each_object(self).to_a
  end
end

get '/' do
  @radio = Radio.all
  erb :index
end

post '/' do
  command = params[:command].to_s
  Media.mplayer(command)
  redirect to("/")
end

post '/stream' do
  stream = Radio.new("Test", params[:stream].to_s)
  url = stream.url
  stream.play(url)
  redirect to("/")
end

