# `amaysim-logger` gem

## Purpose
To have a gem that can be used across different ruby based applications and achieve a consistent way of logging application events.

## Usage
1. Add to `Gemfile`:
```
gem 'amaysim-logger', git: 'git@github.com:amaysim-au/amaysim-logger-ruby.git'
```
2. Run `bundle install`
3. In the application:
```ruby
require 'amaysim_logger'

AmaysimLogger.info('foo') # .info, .debug, .warn, .error, .unknown
# {"msg":"foo","log_timestamp":"2016-01-22 15:46:22 +1100 AEDT"}

AmaysimLogger.info(msg: 'foo')
# {"msg":"foo","log_timestamp":"2016-01-22 15:46:22 +1100 AEDT"}

AmaysimLogger.debug(msg: 'bar', other: :attribute)
# {"msg":"bar","log_timestamp":"2016-01-22 15:46:22 +1100 AEDT","other":"attribute"}

# if a block is given, the log will automatically include start and end time with duration.
AmaysimLogger.warn(msg: 'baz',  other: attribute) { some_callable_stuffs }
# {"msg":"baz","log_timestamp":"2016-01-22 15:46:22 +1100 AEDT","other":"attribute", "start_time":"2016-01-22 15:46:22 +1100 AEDT","end_time":"2016-01-22 15:46:32 +1100 AEDT","duration":10.0}
```

## Rails Helper
There is a rails helper that gives controllers the ability to log each requests.
First you need to add this line into a rails initializer:

```ruby
# /config/initializers/amaysim_logger.rb
require 'amaysim_logger'
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

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

	include AmaysimLogger::RailsControllerHelper

	before_action :wait
	after_action :wait

	def index
		log_request { sleep(1.seconds) }
		render plain: :hello
	end

	private

	def wait
		sleep(2.seconds)
	end
end
```

Then you will have log entries like this:

```
Started GET "/" for ::1 at 2017-01-12 11:06:59 +1100
Processing by ApplicationController#index as HTML
{"msg":"log_request","log_timestamp":"2017-01-12 11:07:02 +1100 AEDT","request_id":"4edd892c-fcc1-423d-aa64-ff29d3ce2884","ip":"::1","user_agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:50.0) Gecko/20100101 Firefox/50.0","endpoint":"http://localhost:3000/","correlation_id":"e8a4ecad-6250-4863-9b79-27989d35b75a","start_time":"2017-01-12 11:07:02 +1100 AEDT","end_time":"2017-01-12 11:07:03 +1100 AEDT","duration":1.000393}
  Rendering text template
  Rendered text template (0.0ms)
{"msg":"log_request","log_timestamp":"2017-01-12 11:07:00 +1100 AEDT","request_id":"4edd892c-fcc1-423d-aa64-ff29d3ce2884","ip":"::1","user_agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:50.0) Gecko/20100101 Firefox/50.0","endpoint":"http://localhost:3000/","correlation_id":"e8a4ecad-6250-4863-9b79-27989d35b75a","start_time":"2017-01-12 11:07:00 +1100 AEDT","end_time":"2017-01-12 11:07:05 +1100 AEDT","duration":5.011884}
Completed 200 OK in 5022ms (Views: 6.1ms | ActiveRecord: 0.0ms)
```
From the log we can see:   

* By including `AmaysimLogger::RailsControllerHelper` we automatically have request logs.
* You can explicitly call `log_request` anytime during any controller action yourself.
* The logs automatically include some request metadata like ip, user agent, endpoint etc.
* Rails is still outputting its standard logs, which is something we needd to fix in the future.

## Correlation Id
Correlation Id is automatically generated if `Correlation-Id` header is not set.
Otherwise the correlation id provided in the HTTP header will be used.
