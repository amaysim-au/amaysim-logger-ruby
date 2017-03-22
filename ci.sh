set -e

apk update
apk add make gcc libc-dev
bundle install
bundle exec rake
