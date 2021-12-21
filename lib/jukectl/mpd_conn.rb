class MpdConn
  def initialize
    puts "[!!!] connecting to mpd..."

    @mpd = MPD.new ENV['MPD_HOST'], ENV['MPD_PORT']
    unless ENV['MPD_PASS'].nil?
      @mpd.password ENV['MPD_PASS']
    end
    @mpd.connect
    @mpd.consume = true
  end

  # TODO: this can probably be implemented as a
  # connection pool and/or add error handling.
  def get_conn
    @mpd
  end
end
