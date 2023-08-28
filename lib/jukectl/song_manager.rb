# Object used to abstract away how data like "path to file" gets read
# and how data like "tags" gets written (that's harder)
#
# simple reads are just metadata from the mpd Song object
# being "tagged" is actually the presence in a playlist.m3u :)

class SongManager
  def initialize(mpd_conn)
    puts "[!] building SongManager"

    @mpd  = mpd_conn
    @song = @mpd.get_conn.queue[0]
    @path = @song.file
  end

  # could attr_reader, paranoid about side effects.
  def path
    @path
  end

  # untested ....?
  def add_tag(tag)
    puts "[=] adding tag for #{@song} #{@path}"
    playlist = @mpd.get_conn.playlists.find {|s| s.name == tag}

    puts "[-] playlist #{playlist} found"

    if playlist.nil?
      puts "[+] song tagged with #{tag}"
      playlist = MPD::Playlist.new(@mpd.get_conn, tag)
    end

    playlist.add(@song)
  end

  def remove_tag(tag)
    puts "[=] removing tag #{tag}"
    playlist = @mpd.get_conn.playlists.find {|s| s.name == tag}

    index = find_song_index_in_playlist(tag, @path)

    unless index.nil?
      puts "[+] song found at index #{index}, removing"
      playlist.delete(index)
    else
      puts "[-] song not tagged with #{tag}"
    end
  end

  private

  def find_song_index_in_playlist(tag, path)
    playlist = @mpd.get_conn.playlists.find {|s| s.name == tag}

    return nil if playlist.nil?

    index = playlist.songs.find_index { |s| s.file == path }
    index
  end
end
