# `amaysim_logger` gem

## Purpose
To have a gem that can be used across different ruby based applications and
achieve a consistent way of logging application events.

## Usage
1. Add to `Gemfile`:

```
gem 'amaysim_logger', git: 'git@github.com:amaysim-au/amaysim-logger-ruby.git'
```
2. Add a logger initialiser to config/initialiser

```
Rails.logger = AmaysimLogger
```

Note: Its a good idea to wrap this in an env var to allow developers to use traditional logs locally:

```
unless ENV['DISABLE_AMAYSIM_LOGGER'] == 'true'
  Rails.logger = AmaysimLogger
end
```

3. Run `bundle install`
4. In the application log as per usual with Rails.logger

```

Rails.logger.info('foo') # .info, .debug, .warn, .error, .unknown
# {
#   "log_timestamp": "2017-02-01 12:43:08 +1100 AEDT",
#   "msg": "foo",
#   "log_level": "info"
# }

Rails.logger.info(msg: 'foo')
# {
#   "log_timestamp": "2017-02-01 12:43:42 +1100 AEDT",
#   "msg": "foo",
#   "log_level": "info"
# }

Rails.logger.error(msg: 'foo', exception: e)
# {
#   "log_timestamp": "2017-02-01 12:43:42 +1100 AEDT",
#   "msg": "foo",
#   "log_level": "info"
#   "exception_message": "some exception message",
#   "exception_class": "SomeException",
#   "exception_backtrace": "<backtrace line separated>"
# }

Rails.logger.debug(msg: 'bar', other: :attribute)
# {
#   "log_timestamp": "2017-02-01 12:44:15 +1100 AEDT",
#   "msg": "bar",
#   "log_level": "info",
#   "other": "attribute"
# }

# if a block is given, the log will automatically include start and end time with duration.
Rails.logger.warn(msg: 'baz', other: :attribute) { sleep 1.45 }
# {
#   "duration": 1.45457,
#   "end_time": "2017-02-01 12:45:02 +1100 AEDT",
#   "log_timestamp": "2017-02-01 12:45:00 +1100 AEDT",
#   "msg": "baz",
#   "log_level": "info",
#   "other": "attribute",
#   "start_time": "2017-02-01 12:45:00 +1100 AEDT"
# }
```

## Keyword Filtering
Keyword filtering is straightforward.

```
AmaysimLogger.filtered_keywords = %w( password email first_name )

AmaysimLogger.info(password: 'foo', key: 'value')
# {"password":"[MASKED]","key":"value"}

AmaysimLogger.debug(soap_response)
# ..... <email>[MASKED]</email> ......
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
  "msg": "Web request",
  "log_level": "info",
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
  "msg": "foo",,
  "log_level": "info",
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
  "msg": null,,
  "log_level": "info",
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
  "msg": "Web request",
  "log_level": "info",
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
  "msg": "Web request",
  "log_level": "info",
  "request_id": "6a2a792b-4a96-4179-adf2-106c1028df7c",
  "start_time": "2017-02-01 12:47:08 +1100 AEDT",
  "user_agent": "Mozilla/5.0"
}
```

From the log we can see:   

* We automatically have request logs.
* You can explicitly call `controller request` anytime during any controller action yourself.
* The logs automatically include some request metadata like ip, user agent, endpoint etc.

### Common log entries for all controllers

To add common log params across all controllers then
Add something like this to an intialiser
```
  ActiveSupport.on_load(:action_controller) do
    AmaysimLogger.add_to_log_context(app: 'your app name', foo: 'foo')
  end
```

### Configuration

By default the ActiveRecord, ActiveJob, ActionController and ActionView logs are
disabled. These can be re-enabled in an initializer.

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

Please ensure the correlation id is passed to downstream systems so we can link a request through multiple microservices

```
Header key: "Correlation-ID"
Header value: eg. "568652a8-2d54-4540-940d-ca48836ec70f"
```

## Running tests

* locally:
```
bundle install
bundle exec rake
```

* with docker:
```
docker-compose run test
```