require 'timecop'
require 'active_support/notifications'
require 'action_dispatch/http/mime_type'
require 'action_dispatch/http/request'

# rubocop:disable Metrics/BlockLength
RSpec.describe AmaysimLogger::EventHandler do
  let(:start_time) { DateTime.parse('2016-01-22 15:46:22.0000 +1100') }
  let(:start_timestamp) { '2016-01-22 15:46:22 +1100 AEDT' }

  before do
    Timecop.freeze(start_time)
    output.truncate(0)
  end

  let(:base_hash) do
    {
      log_timestamp: start_timestamp,
      remote_ip: '127.0.0.1',
      request_id: '7cfd18e6-2528-461e-bc5f-0aeaa01bd19e',
      user_agent: 'Mozilla/5.0',
      correlation_id: '138185a4-be6d-4061-b969-ca8c90290f23'
    }
  end

  let(:handler) { described_class.new }
  let(:headers) do
    env = {
      'HTTP_USER_AGENT' => 'Mozilla/5.0',
      'HTTP_CORRELATION_ID' => '138185a4-be6d-4061-b969-ca8c90290f23',
      'action_dispatch.request_id' => '7cfd18e6-2528-461e-bc5f-0aeaa01bd19e',
      'action_dispatch.remote_ip' => '127.0.0.1'
    }

    ActionDispatch::Http::Headers.from_hash(env)
  end
  let(:event) do
    ActiveSupport::Notifications::Event.new(
      'process_action.action_controller',
      Time.now,
      Time.now,
      rand,
      **params
    )
  end

  let(:output) { StringIO.new }
  let(:logger) { AmaysimLogger::Logger.new(output) }

  describe 'basic request' do
    let(:params) do
      { headers: headers }
    end

    it 'parses the process action event into a hash' do
      output = handler.call(event)

      expect(output).to eq(base_hash)
    end
  end

  describe 'basic request with log context as a hash' do
    let(:params) do
      { headers: headers }
    end

    before do
      AmaysimLogger.log_context = { foo: 'bar' }
    end

    after do
      AmaysimLogger.log_context = {}
    end

    it 'parses the process action event into a hash' do
      output = handler.call(event)

      expect(output).to eq(base_hash.merge(foo: 'bar'))
    end
  end

  describe 'basic request with log context as a string' do
    let(:params) do
      { headers: headers }
    end

    before do
      AmaysimLogger.log_context = 'foobar'
    end

    after do
      AmaysimLogger.log_context = {}
    end

    it 'parses the process action event into a hash' do
      output = handler.call(event)

      expect(output).to eq(base_hash.merge(log_context: 'foobar'))
    end
  end

  describe 'request with exception' do
    let(:params) do
      {
        headers: headers,
        exception_object: TestException.new('Oh no')
      }
    end

    it 'parses the process action event into a hash' do
      output = handler.call(event)

      expect(output).to eq(
        base_hash.merge(
          exception: 'TestException',
          exception_msg: 'Oh no',
          exception_backtrace: "line1\nline2\nline3"
        )
      )
    end
  end
end
