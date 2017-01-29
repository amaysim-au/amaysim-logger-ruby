# `amaysim_logger` gem

## Purpose
To have a gem that can be used across different ruby based applications and achieve a consistent way of logging application events.

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
#   "level": "INFO",
#   "log_timestamp": "2017-01-27 13:11:14 +1100 AEDT",
#   "msg": "foo"
# }

AmaysimLogger.info(msg: 'foo')
# {
#   "level": "INFO",
#   "log_timestamp": "2017-01-27 13:11:44 +1100 AEDT",
#   "msg": "foo"
# }

AmaysimLogger.debug(msg: 'bar', other: :attribute)
# {
#   "level": "DEBUG",
#   "log_timestamp": "2017-01-27 13:12:15 +1100 AEDT",
#   "msg": "bar",
#   "other": "attribute"
# }

# if a block is given, the log will automatically include start and end time with duration.
AmaysimLogger.warn(msg: 'baz',  other: :attribute) { sleep 1 }
# {
#   "duration": 1.024089,
#   "end_time": "2017-01-27 13:40:44 +1100 AEDT",
#   "level": "WARN",
#   "log_timestamp": "2017-01-27 13:40:44 +1100 AEDT",
#   "msg": "baz",
#   "other": "attribute",
#   "start_time": "2017-01-27 13:40:43 +1100 AEDT"
# }

# if the block raises an exception, it will be added to the output.
AmaysimLogger.warn(msg: 'baz',  other: :attribute) { raise StandardError, "Ooops!" }
# {
#   "duration": 0.000376,
#   "end_time": "2017-01-27 13:41:58 +1100 AEDT",
#   "exception": "StandardError",
#   "exception_backtrace": "<truncated>",
#   "exception_msg": "Ooops!",
#   "level": "WARN",
#   "log_timestamp": "2017-01-27 13:41:58 +1100 AEDT",
#   "msg": "baz",
#   "other": "attribute",
#   "start_time": "2017-01-27 13:41:58 +1100 AEDT"
# }
```

## Rails

It should Just Work:tm:.