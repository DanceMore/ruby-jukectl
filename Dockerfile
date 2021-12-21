FROM debian:bullseye-slim
MAINTAINER rk <dancemore@dancemore.xyz>

# apt updates
RUN apt -y update
RUN apt -y upgrade

# ruby and development tools
RUN apt -y install ruby bundler git

# mpd controller client
RUN apt -y install mpc ncmpcpp
VOLUME /music

# user account
RUN adduser --disabled-password --home=/app --gecos "" app

# add the code
ADD . /app
RUN chown -R app:app /app

# build it
RUN su - app -c 'bundle install --path=vendor/bundle'

# run it
ADD .docker/files/run.sh /
EXPOSE 4567
CMD ["/run.sh"]
