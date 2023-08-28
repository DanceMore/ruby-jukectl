# simple Structure to hold the internal state of "which Tags does the jukebox select from"
# it is based on Set Maths and/or Boolean Logic. fields are Arrays or comma-strings in JSON
# so you can have multiple tags active or excluded at once.
#
# `any`: any Song with any of these Tags can be played
# `not`: Set() logic exclude Songs with any of these tags from being played
#
# default sets to {any: jukebox, not: explicit}, which I consider a sane default for radio-heads :)

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
