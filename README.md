# jukectl

a little doo-dad that uses `mpd` as the Database and Player to be your own private jukebox... thingie.

![jukectl-arch-diagram](https://github.com/DanceMore/jukectl/assets/79212033/23d3e014-aadd-4268-9ab4-a60f2135f3c8)

## history

what you are seeing here is actually the 3rd or 4th iteration of an idea, where each copy became progressively simpler and simpler.

the first design was a fully fledged RubyOnRails app with Scaffolding and HTML and data stored in MySQL; the works.

but Rails got slow and I decided to try my hand in Sinatra, still using ActiveRecord and an entire Database and HTML templates.

progress was slow, often because I needed to make entire HTML templates where a small JSON response would do ... and I had lots of bugs and complexity related to Database State differening from MPD's database.

so I had the idea to make it even leaner! Sinatra with JSON input and output only! no Database, only MPD as the backend!

under the hood, a `Tag` is just a `.m3u` playlist that MPD reads and `jukectl` can do the Set() operations in-memory :)

since the switch over to Sinatra+JSON+mpd-as-database, `jukectl` has served me dutifully on a near daily basis for years now :)

(I promise I'll clean up the code more some day)

```
TODO

clean up code; document

document API

document how to fire the containerized ncurses CLI (which I haven't finished installing / wrapping up)

add environment var for default json tags
  maybe encode in base64 lololol
```
