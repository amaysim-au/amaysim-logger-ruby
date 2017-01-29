require 'timecop'

RSpec.describe AmaysimLogger do
  describe Logger do
    include_examples 'logging', :info, 'INFO'
    include_examples 'logging', :debug, 'DEBUG'
    include_examples 'logging', :warn, 'WARN'
    include_examples 'logging', :error, 'ERROR'
    include_examples 'logging', :unknown, 'ANY'
  end
end
