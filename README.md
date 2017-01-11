# `amaysim-logger` gem

## Purpose
To have a gem that can be used across different ruby based applications and achieve a consistent way of logging application events.

## Usage
1. Add to `Gemfile`:
```
gem 'amaysim-logger', git: git@github.com:amaysim-au/amaysim-logger-ruby.git
```
2. Run `bundle install`
3. In the application:
```ruby
require 'amaysim-logger`

AmaysimLogger.info('foo') # .info, .debug, .warn, .error, .unknown
# {"msg":"foo","log_timestamp":"2016-01-22 15:46:22 +1100 AEDT"}

AmaysimLogger.info(msg: 'foo')
# {"msg":"foo","log_timestamp":"2016-01-22 15:46:22 +1100 AEDT"}

AmaysimLogger.debug(msg: 'bar', other: :attribute)
# {"msg":"bar","log_timestamp":"2016-01-22 15:46:22 +1100 AEDT","other":"attribute"}

AmaysimLogger.warn(msg: 'baz',  other: attribute) { some_callable_stuffs }
# {"msg":"baz","log_timestamp":"2016-01-22 15:46:22 +1100 AEDT","other":"attribute", "start_time":"2016-01-22 15:46:22 +1100 AEDT","end_time":"2016-01-22 15:46:32 +1100 AEDT","duration":10.0}
```

## Rails Helper
There is a rails helper that gives controllers the ability to log each requests.
First you need to add this line into a rails initializer:

```ruby
Rails.logger = AmaysimLogger
```

Then in your controller:

```ruby
require 'amaysim_logger/rails_controller_helper'

class OrdersController < ApplicationController
  include AmaysimLogger::RailsControllerHelper

  def some_action
    # implementations
  end
end
```

By including the `AmaysimLogger::RailsControllerHelper` you automatically get logs for each request on each action:

```
{"msg":"log_request","log_timestamp":"2016-01-22 15:46:22 +1100 AEDT","request_id":"uuid","ip":"1.2.3.4","user_agent":"Chrome","endpoint":"http://amaysim.com.au","correlation_id":"generated-uuid","start_time":"2016-01-22 15:46:22 +1100 AEDT","end_time":"2016-01-22 15:46:32 +1100 AEDT","duration":10.0}
```

There is also a method available for all controllers that include the module: `add_to_log_context`. It can be used when you need to log multiple entries and want to set some common attributes that are shared across those entries. One use case would be multiple log entries for one single api call:

```ruby
require 'amaysim_logger/rails_controller_helper'

class SomeController < ApplicationController
  include AmaysimLogger::RailsControllerHelper

  def some_action
    add_to_log_context(api_key: request.headers['API-KEY'])
    do_something1
    Rails.logger.info('something1')
    do_something2
    Rails.logger.info('something2')
    do_something3
    Rails.logger.info('something3')
  end
end
```

Then you will have `api_key` in all 3 log entries above.
`request_id`, `ip`, `user_agent`, `endpoint` are included in the log context by default.

## Correlation Id
Correlation Id is automatically generated if `Correlation-Id` header is not set.
Otherwise the correlation id provided in the HTTP header will be used.
