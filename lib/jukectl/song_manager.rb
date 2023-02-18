class SongManager
  def initialize(mpd_conn)
    puts "[!!!] building SongManager"

    @mpd  = mpd_conn
    @song = @mpd.get_conn.queue[0]
    @path = @song.file
  end

  def path
    @path
  end

  def add_tag(tag)
    puts "[!!!] adding tag for #{@song} #{@path}"
    require 'pp'
    pp @song
    playlist = @mpd.get_conn.playlists.find {|s| s.name == tag}

    puts "[-] #{playlist}"

    if playlist.nil?
      playlist = MPD::Playlist.new(@mpd.get_conn, tag)
    end

    puts "[-] #{playlist}"

    playlist.add(@song)
  end

  def remove_tag(tag)
    puts "[!!!] removing tag #{tag}"
    playlist = @mpd.get_conn.playlists.find {|s| s.name == tag}

    index = walk_playlist(tag, @path)

    unless index.nil?
      puts "[!!!] song found at index #{index}"
      playlist.delete(index)
    else
      puts "[-] song not tagged with #{tag}"
    end
  end

  private

  def walk_playlist(tag, path)
    playlist = @mpd.get_conn.playlists.find {|s| s.name == tag}
    return nil if playlist.nil?

    playlist.songs.each_with_index do |s, i|
      return i if s.file == path
    end

    nil
  end
end
