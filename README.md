# README

## The application

The Rails application creates new `posts` at a regular interval (via a scheduled rake task), that are enqueued to be `processed` (via a background worker). The website shows a list of posts and their processing status.

## Processes

- Web Process: `bundle exec puma -w 2 -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-production}`
- Worker Process: `bin/rails jobs:work`. A persistent worker process through DelayedJob.
- Scheduled Task: `bin/rake posts:create`, to be run at regular intervals, e.g. once per minute, or every day at 11am.

## Local Setup

Assuming Ruby and Postgres are installed locally...

1. `bin/setup`
2. `bin/rails s`
3. Run tests: `bin/rspec`
