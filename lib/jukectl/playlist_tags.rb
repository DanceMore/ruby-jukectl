class PlaylistTags
  def initialize
    @tags = {}
    @tags['any'] = ['jukebox']
    @tags['not'] = ['explicit']
  end

  def tags
    @tags
  end

  def any_tags!(tag_arr)
    @tags['any'] = tag_arr
  end

  def not_tags!(tag_arr)
    @tags['not'] = tag_arr
  end
end
