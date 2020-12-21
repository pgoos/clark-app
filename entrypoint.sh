#!/bin/bash

if [ "$#" == 0 ]
then
  rm -f /var/app/tmp/pids/server.pid || :

  bundle install -j4

  scripts/init_database

  bundle exec rails db:migrate

  mv /app/docker/nginx.example.conf /etc/nginx/nginx.conf
  mv /app/public /assets

  exec bundle exec rails server -b '0.0.0.0'
else
  exec $@
fi
