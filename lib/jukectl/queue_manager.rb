class QueueManager
  def initialize(mpd_conn, tag_mgr)
    puts "[!!!] building QueueManager"

    # set instance variables
    @mpd = mpd_conn
    @tags  = tag_mgr

    # create a new song list and shuffle it
    @queue = new_song_list
    shuffle!
  end

  # I thought the @ accessor did this ..?
  def queue
    @queue
  end

  def new_song_list
    shuffle!
  end

  def add_song!
    if @mpd.get_conn.queue.length < 2
      add_random_song
      return true
    else
      return false
    end
  end

  def skip!
    @mpd.get_conn.next
  end

  def now_playing
    @mpd.get_conn.queue[0, 2]
  end

  def shuffle!
    tags = @tags.tags

    # grab our jukebox songs
    songs_any = get_songs_by_tags(tags['any'])
    songs_any -= get_songs_by_tags(tags['not']) unless tags['not'].nil? || tags['not'].empty?


    final_songs = songs_any

    if final_songs.empty?
      fail RuntimeError, "[!!!] no valid songs to play. bad human! no cookie!"
    end

    to_loglines(final_songs)

    # finalize the data for usage
    @songs = final_songs
    @songs.shuffle!
  end

  private

  def get_songs_by_tags(tags)
    return [] if tags.nil?

    tags.each_with_object([]) do |tag, songs|
      playlist = @mpd.get_conn.playlists.find { |s| s.name == tag }
      next if playlist.nil?

      songs.concat(playlist.songs)
    end
  end

  def to_loglines(queue)
    #queue.each do |song|
    #  logger.debug "[-] #{song} => #{song.file}"
    #end
  end

  def add_random_song
    song = @songs.pop

    if song.nil?
      shuffle!
      song = @songs.pop
    end

    if song.nil?
      fail "no songs to add"
    end

    @mpd.get_conn.where({file: song.file}, {add: true})
    @mpd.get_conn.play
  end
end
