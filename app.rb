def setup
  unless File.exist?('/tmp/mplayer-control')
    `mkfifo /tmp/mplayer-control`
  end
end

def mplayer(command)
  `echo "#{command}" > /tmp/mplayer-control`
end

def play(source)
  setup
  `mplayer -slave -input file=/tmp/mplayer-control #{source}`
end

get '/' do
  erb :index
end

post '/' do
  command = params[:command].to_s
  mplayer(command)
  redirect to("/")
end

post '/stream' do
  stream = params[:stream].to_s
  play(stream)
  redirect to("/")
end
