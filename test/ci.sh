#!/bin/bash

cd spec/dummy && bundle install --without debug && bundle exec rake db:create && bundle exec rake db:migrate && cd ../../ && bundle exec rake
