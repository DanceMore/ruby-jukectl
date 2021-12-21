class QueueManager
  def initialize(mpd_conn, tag_mgr)
    puts "[!!!] building QueueManager"

    @mpd = mpd_conn
    @tags  = tag_mgr
    @songs = new_song_list

    shuffle!
  end

  def queue
    @songs
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

  # TODO: smaller method
  def shuffle!
    tags = @tags.tags

    # grab our jukebox songs
    songs_any = []
    tags['any'].each do |tag|
      songs_any << songs_by_tag(tag)
    end

    songs_any.flatten!
    to_loglines(songs_any)

    # remove excluded tags
    # TODO: I hate this implementation.
    unless tags['not'].nil?
      tags['not'].each do |tag|
        playlist = @mpd.get_conn.playlists.find {|s| s.name == tag}

        unless playlist.nil?
          playlist.songs.each do |s|
            puts "[+] removing #{s.file}"
            songs_any.delete s
          end
        end
      end
    end

    # this made more sense as a Set operation, but it's
    # a useful identifier for following code flow.
    final_songs = songs_any

    # TODO: we currently because this is broken
    # no tags? return 100 songs.
    if final_songs.length < 1
      fail RuntimeError, "[!!!] no valid songs to play. bad human! no cookie!"
    end

    # DEBUG: print final set
    # this will probably explode on all songs :P
    to_loglines(final_songs)

    # finalize the data for usage
    @songs = final_songs.to_a
    @songs.shuffle!
  end

  private

  def songs_by_tag(tag)
    songs = []
    playlist = @mpd.get_conn.playlists.find {|s| s.name == tag}

    unless playlist.nil?
      playlist.songs.each do |s|
        songs << s
      end
    end

    songs
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
