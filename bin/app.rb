#!/usr/bin/env ruby

require 'jukectl'

require 'sinatra/base'
require 'sinatra/json'
require 'json'

class WebApp < Sinatra::Base
  # docker
  set :bind, '0.0.0.0'
  set :views , File.expand_path('../../views', __FILE__)

  # less features = better
  set :sessions, false
  enable :logging

  configure do
    @mpd_conn  = MpdConn.new
    @tag_mgr   = PlaylistTags.new
    @queue_mgr = QueueManager.new(@mpd_conn, @tag_mgr)

    setup_scheduler unless defined?(Rake) || defined?(IRB) || ENV['DRYRUN']
  end

  def setup_scheduler
    # scheduler
    scheduler = Rufus::Scheduler.new
    scheduler.every("3s") do
      print "."
      @queue_mgr.add_song!
    end
  end

  # method to convert Arrays of MPD::Songs to Arrays
  # of "MPD::Song.file strings"
  # ( basically just display formatting cuz lazy )
  #
  def queue_to_filenames(song_array)
    filename_array = []

    song_array.each do |song|
      filename_array << song.file
    end

    filename_array
  end

  # default is to show "Now Playing"
  get '/' do
    arr = @queue_mgr.now_playing

    # format it ;)
    res = queue_to_filenames(arr)
    json res
  end

  # show me the entire queue ;)
  get '/queue' do
    arr = @queue_mgr.queue

    # songs are added via Array.pop which
    # returns the last element of the array.
    #
    # we want to display it in playback order :)
    arr = arr.reverse

    # format output
    res = queue_to_filenames(arr)
    json res
  end

  ### example tags struct
  #  {
  #    "any": [
  #      "jukebox",
  #      "chill"
  #    ],
  #    "not": [
  #      "explicit"
  #    ]
  #  }
  get '/tags' do
    res = @tag_mgr.tags
    json res
  end

  post '/reload' do
    # sample the head of the queue...
    old_pls = @queue_mgr.queue.last(4).reverse

    # DESTROY THE QUEUE AND RESHUFFLE WITH NEW TAGS
    @queue_mgr.shuffle!

    # sample again...
    new_pls = @queue_mgr.queue.last(4).reverse

    # format it ;)
    res_old = queue_to_filenames(old_pls)
    res_new = queue_to_filenames(new_pls)

    json({old: res_old, new: res_new})
  end

  post '/tags' do
    content_type :json

    begin
      request_body = JSON.parse(request.body.read)
      tags_any = request_body['any'] || []
      tags_not = request_body['not'] || []
    rescue JSON::ParserError => e
      error_msg = "Error occurred while parsing the request body: #{e}"
      halt 400, { error: error_msg }.to_json
    end

    @tag_mgr.any_tags!(tags_any)
    @tag_mgr.not_tags!(tags_not)

    # Shuffle the queue with new tags
    @queue_mgr.shuffle!

    { tags: @tag_mgr.tags }.to_json
  end

  post '/song/tags' do
    song_mgr  = SongManager.new(@mpd_conn)

    # make sure we have a Request Body
    begin
      @body = request.body.read
      data = JSON.parse(@body)
      puts "[!] PARSED DATA => #{data['add']}"
      puts "[!] PARSED DATA => #{data['remove']}"
    rescue Exception => e
      @runtime.error(e)
      @msg = "Error occured reading POST body."
      halt 500, json({:error => @msg})
    end

    tags_add = data['add']
    tags_rm  = data['remove']

    res = {}
    res['song']    = song_mgr.path
    res['added' ]  = []
    res['removed'] = []
    unless tags_add.nil?
      tags_add.each do |t|
        res['added'] << t
        song_mgr.add_tag(t)
      end
    end

    unless tags_rm.nil?
      tags_rm.each do |t|
        res['removed'] << t
        song_mgr.remove_tag(t)
      end
    end

    json res
  end

  post '/skip' do
    np = @queue_mgr.now_playing
    @queue_mgr.skip!

    res = {}
    res['skipped'] = np[0].file
    res['new']     = np[1].file

    json res
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
