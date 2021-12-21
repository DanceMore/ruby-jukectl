#!/bin/sh

/etc/init.d/mpd start
mpc update
mpc play

su app -c "cd /app; bundle exec bin/app.rb"
