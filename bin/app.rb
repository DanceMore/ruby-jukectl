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

  def initialize(*args)
    #we want to still *be* a Sinatra::Base
    super

    @mpd_conn  = MpdConn.new
    @tag_mgr   = PlaylistTags.new
    @queue_mgr = QueueManager.new(@mpd_conn, @tag_mgr)

    unless defined?(Rake) || defined?(IRB) || ENV['DRYRUN']
      # scheduler
      scheduler = Rufus::Scheduler.new
      scheduler.every("3s") do
        print "."
        @queue_mgr.add_song!
      end
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

    res = queue_to_filenames(arr)
    json res
  end

  # show me the entire queue ;)
  get '/queue' do
    arr = @queue_mgr.queue

    # songs are added via Array.pop which
    # returns the last element of the array.
    #
    # we want the API to display it in playback order :)
    arr = arr.reverse

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
    arr = @queue_mgr.queue
    arr = arr.reverse
    old_pls = arr[0..3]

    # DESTROY THE QUEUE AND RESHUFFLE WITH NEW TAGS
    @queue_mgr.shuffle!

    # sample again...
    arr = @queue_mgr.queue
    arr = arr.reverse
    new_pls = arr[0..3]

    # format it ;)
    res_old = queue_to_filenames(old_pls)
    res_new = queue_to_filenames(new_pls)

    json({:old => res_old, :new => res_new})
  end

  # I think this all sucks but whatever,
  # it probably worked in the past, maybe it's still good...
  post '/tags' do
    # make sure we have a Request Body
    begin
      @body = request.body.read
      data = JSON.parse(@body)
      puts "[!] PARSED DATA => #{data['any']}"
      puts "[!] PARSED DATA => #{data['not']}"
    rescue Exception => e
      @runtime.error(e)
      @msg = "Error occured reading POST body."
      halt 500, json({:error => @msg})
    end

    tags_any = data['any']
    tags_not = data['not']

    if tags_not.nil?
      tags_not = []
    end

    # TODO: ensure the data doesn't suck when it gets here
    @tag_mgr.any_tags! tags_any
    @tag_mgr.not_tags! tags_not

    # DESTROY THE QUEUE AND RESHUFFLE WITH NEW TAGS
    @queue_mgr.shuffle!

    # return the new tag list
    res = @tag_mgr.tags

    json res
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
