# `amaysim_logger` gem

## Purpose
To have a gem that can be used across different ruby based applications and
achieve a consistent way of logging application events.

## Usage
1. Add to `Gemfile`:

```
gem 'amaysim_logger', git: 'git@github.com:amaysim-au/amaysim-logger-ruby.git'
```

2. Run `bundle install`
3. In the application:

```ruby
require 'amaysim_logger'

AmaysimLogger.info('foo') # .info, .debug, .warn, .error, .unknown
# {
#   "log_timestamp": "2017-02-01 12:43:08 +1100 AEDT",
#   "msg": "foo"
# }

AmaysimLogger.info(msg: 'foo')
# {
#   "log_timestamp": "2017-02-01 12:43:42 +1100 AEDT",
#   "msg": "foo"
# }

AmaysimLogger.debug(msg: 'bar', other: :attribute)
# {
#   "log_timestamp": "2017-02-01 12:44:15 +1100 AEDT",
#   "msg": "bar",
#   "other": "attribute"
# }

# if a block is given, the log will automatically include start and end time with duration.
AmaysimLogger.warn(msg: 'baz', other: :attribute) { sleep 1.45 }
# {
#   "duration": 1.45457,
#   "end_time": "2017-02-01 12:45:02 +1100 AEDT",
#   "log_timestamp": "2017-02-01 12:45:00 +1100 AEDT",
#   "msg": "baz",
#   "other": "attribute",
#   "start_time": "2017-02-01 12:45:00 +1100 AEDT"
# }
```

## Rails
It should Just Work:tm:.

You automatically get logs for each request on each action:

```
{
  "correlation_id": "f79fd4bb-c591-4335-a90a-74994bfe5d9f",
  "duration": 0.576696,
  "end_time": "2017-02-01 12:38:00 +1100 AEDT",
  "endpoint": "http://amaysim.com.au/",
  "ip": "::1",
  "log_timestamp": "2017-02-01 12:37:59 +1100 AEDT",
  "msg": "log_request",
  "request_id": "04780cc0-fead-448d-907a-381089eb221b",
  "start_time": "2017-02-01 12:37:59 +1100 AEDT",
  "user_agent": "Mozilla/5.0"
}
```

There is also a method available for all controllers `add_to_log_context`. It
can be used when you need to some common attributes that are shared across
multiple log entries during the request.

```ruby
class ApplicationController < ActionController::Base
  def index
    add_to_log_context(foo: :bar)
    logger.info('foo')
    logger.info(baz: :bar)
    log_request do
      sleep 1.5
    end
  end
end
```

Then you will have log entries like this:
```
{
  "correlation_id": "568652a8-2d54-4540-940d-ca48836ec70f",
  "endpoint": "http://amaysim.com.au/",
  "foo": "bar",
  "ip": "::1",
  "log_timestamp": "2017-02-01 12:47:08 +1100 AEDT",
  "msg": "foo",
  "request_id": "6a2a792b-4a96-4179-adf2-106c1028df7c",
  "user_agent": "Mozilla/5.0"
}
{
  "baz": "bar",
  "correlation_id": "568652a8-2d54-4540-940d-ca48836ec70f",
  "endpoint": "http://amaysim.com.au/",
  "foo": "bar",
  "ip": "::1",
  "log_timestamp": "2017-02-01 12:47:08 +1100 AEDT",
  "msg": null,
  "request_id": "6a2a792b-4a96-4179-adf2-106c1028df7c",
  "user_agent": "Mozilla/5.0"
}
{
  "correlation_id": "568652a8-2d54-4540-940d-ca48836ec70f",
  "duration": 1.503092,
  "end_time": "2017-02-01 12:47:10 +1100 AEDT",
  "endpoint": "http://amaysim.com.au/",
  "foo": "bar",
  "ip": "::1",
  "log_timestamp": "2017-02-01 12:47:08 +1100 AEDT",
  "msg": "log_request",
  "request_id": "6a2a792b-4a96-4179-adf2-106c1028df7c",
  "start_time": "2017-02-01 12:47:08 +1100 AEDT",
  "user_agent": "Mozilla/5.0"
}
{
  "correlation_id": "568652a8-2d54-4540-940d-ca48836ec70f",
  "duration": 2.223704,
  "end_time": "2017-02-01 12:47:10 +1100 AEDT",
  "endpoint": "http://amaysim.com.au/",
  "ip": "::1",
  "log_timestamp": "2017-02-01 12:47:08 +1100 AEDT",
  "msg": "log_request",
  "request_id": "6a2a792b-4a96-4179-adf2-106c1028df7c",
  "start_time": "2017-02-01 12:47:08 +1100 AEDT",
  "user_agent": "Mozilla/5.0"
}
```

From the log we can see:   

* We automatically have request logs.
* You can explicitly call `log_request` anytime during any controller action yourself.
* The logs automatically include some request metadata like ip, user agent, endpoint etc.

### Configuration

By default the ActiveRecord, ActiveJob, ActionController and ActionView logs are
disabled. These can be reenabled in an initailizer.

```
# /config/initializers/amaysim_logger.rb

Rails.application.configure do
  config.amaysim_logger.disable_action_view_logs = false
  config.amaysim_logger.disable_action_controller_logs = false
  config.amaysim_logger.disable_active_record_logs = false
  config.amaysim_logger.disable_active_job_logs = false
end
```

## Correlation ID
Correlation ID is automatically generated if `Correlation-ID` header is not set.
Otherwise the correlation id provided in the HTTP header will be used.
