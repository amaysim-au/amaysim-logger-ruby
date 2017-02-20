require 'active_support'
require 'timecop'
require 'request_store'
# rubocop:disable RSpec/MessageSpies
RSpec.describe AmaysimLogger do
  let(:timestamp) { '2016-01-22 15:46:22 +1100 AEDT' }
  let(:logger) { described_class.logger }
  let(:start_time) { DateTime.parse('2016-01-22 15:46:22 +1100') }
  let(:end_time) { DateTime.parse('2016-01-22 15:46:32 +1100') }
  let(:log_timestamp) { start_time }
  let(:message) { 'my_message' }
  let(:log_level) { 'info' }
  let(:multiple_lines_message) do
    <<-XML
<root>
<element>first line</element>
</root>
    XML
  end
  before do
    Timecop.freeze(start_time)
    described_class.log_context = nil
  end

  describe 'info, debug, warn, error, unknown' do
    context 'non hash input' do
      let(:expected) do
        %({"msg":"#{message}","log_timestamp":"#{timestamp}","log_level":"unknown"})
      end

      it 'logs non hash input' do
        expect(logger).to receive(:unknown).with(expected)
        described_class.unknown(message)
      end
    end

    context 'multi line' do
      # rubocop:disable Metrics/LineLength
      let(:expected) do
        {
          msg: "<root>\n<element>first line</element>\n</root>",
          log_timestamp: '2016-01-22 15:46:22 +1100 AEDT',
          log_level: 'warn'
        }.to_json
      end

      it 'logs a multiple lines string' do
        expect(logger).to receive(:warn).with(expected)
        described_class.warn(multiple_lines_message)
      end
    end

    context 'trims white space' do
      let(:message) { "  b y \n\n   " }
      let(:expected) { %({"msg":"b y","log_timestamp":"#{timestamp}","log_level":"info"}) }

      it 'trims white space in log entries' do
        expect(logger).to receive(:info).with(expected)
        described_class.info(message)
      end
    end

    context 'masks keyword' do
      before do
        described_class.filtered_keywords = %w(password)
      end

      it 'masks the filtered keywords for a hash log message' do
        expected = '{"msg":"","log_timestamp":"2016-01-22 15:46:22 +1100 AEDT","log_level":"info","password":"[MASKED]","foo":"bar"}'
        expect(logger).to receive(:info).with(expected)
        described_class.info(password: '1234', foo: 'bar')
      end

      it 'masks the filtered keywords for a string json message' do
        expected = '{"msg":"{\"password\":\"[MASKED]\",\"foo\":\"bar\"}","log_timestamp":"2016-01-22 15:46:22 +1100 AEDT","log_level":"info"}'
        expect(logger).to receive(:info).with(expected)
        described_class.info('{ "password" : "1234", "foo" : "bar" }')
      end

      it 'masks the filtered keywords for a string xml message' do
        expected = '{"msg":"\\u003cpassword\\u003e[MASKED]\\u003c/password\\u003e","log_timestamp":"2016-01-22 15:46:22 +1100 AEDT","log_level":"info"}'
        expect(logger).to receive(:info).with(expected)
        described_class.info('<Password>abc</Password>')
      end

      it 'masks a block result' do
        expected = '{"msg":"\\u003cpassword\\u003e[MASKED]\\u003c/password\\u003e","log_timestamp":"2016-01-22 15:46:22 +1100 AEDT","log_level":"info"}'
        expect(logger).to receive(:info).with(expected)
        described_class.info { '<Password>abc</Password>' }
      end

      it 'masks a nested hash' do
        expected = '{"msg":{"password":"[MASKED]","foo":"bar"},"log_timestamp":"2016-01-22 15:46:22 +1100 AEDT","log_level":"info"}'
        expect(logger).to receive(:info).with(expected)
        described_class.info(msg: { password: :blah, foo: :bar })
      end
    end
  end

  describe '.add_to_log_context' do
    context 'when AmaysimLogger.log_context is not a hash' do
      it 'sets AmaysimLogger.log_context as-is' do
        foo = Object.new
        described_class.log_context = :whatever
        described_class.add_to_log_context(foo)
        expect(described_class.log_context).to eq(foo)
      end
    end

    context 'when AmaysimLogger.log_context is a hash' do
      it 'merges the given hash into AmaysimLogger.log_context' do
        described_class.log_context = { foo: :bar }
        described_class.add_to_log_context(bar: :baz)
        expect(described_class.log_context).to eq(foo: :bar, bar: :baz)
      end
    end
  end

  context 'without a block' do
    let(:log_msg) do
      {
        msg: message,
        log_timestamp: timestamp,
        log_level: log_level
      }.to_json
    end

    describe '#info' do
      let(:log_level) { 'info' }
      it 'logs info messages' do
        expect(logger).to receive(:info).with log_msg
        described_class.info msg: message
      end
    end

    describe '#debug' do
      let(:log_level) { 'debug' }
      it 'logs info messages' do
        expect(logger).to receive(:debug).with log_msg
        described_class.debug msg: message
      end
    end

    describe '#warn' do
      let(:log_level) { 'warn' }
      it 'logs info messages' do
        expect(logger).to receive(:warn).with log_msg
        described_class.warn msg: message
      end
    end

    describe '#error' do
      let(:log_level) { 'error' }
      it 'logs error messages' do
        expect(logger).to receive(:error).with log_msg
        described_class.error msg: message
      end
    end

    describe '#<<' do
      let(:log_level) { 'info' }
      it 'logs info message' do
        expect(logger).to receive(:info).with log_msg
        described_class << message
      end
    end
  end

  describe 'with a block' do
    let(:start_log_msg) do
      {
        msg: message,
        log_timestamp: timestamp,
        log_level: log_level,
        start_time: timestamp
      }.to_json
    end
    let(:end_log_msg) do
      {
        msg: message,
        log_timestamp: timestamp,
        log_level: log_level,
        start_time: timestamp,
        end_time: '2016-01-22 15:46:32 +1100 AEDT',
        duration: 10.0
      }.to_json
    end
    let(:block_return_msg) { 'return me as result' }

    before do
      allow(logger).to receive :info
    end

    context 'without exception' do
      after do
        described_class.info(msg: message) { Timecop.freeze(end_time) }
      end

      it 'logs the end time and duration' do
        expect(logger).to receive(:info).with end_log_msg
      end

      it 'returns the block return' do
        expect(
          described_class.info(msg: message) { block_return_msg }
        ).to eq block_return_msg
      end
    end

    context 'with exception' do
      let(:end_log_msg) do
        {
          msg: message,
          log_timestamp: timestamp,
          log_level: log_level,
          start_time: timestamp,
          exception_class: 'RuntimeError',
          exception_message: 'stinky things happen',
          end_time: '2016-01-22 15:46:32 +1100 AEDT',
          duration: 10.0
        }.to_json
      end

      let(:stinky_thing) do
        described_class.info(msg: message) do
          Timecop.freeze(end_time)
          raise 'stinky things happen'
        end
      end

      it 'logs end_log_msg on exception' do
        expect(logger).to receive(:info).with end_log_msg
        begin
          stinky_thing
        rescue RuntimeError # rubocop:disable Lint/HandleExceptions
        end
      end

      it 'logs and raises an exception' do
        expect { stinky_thing }.to raise_error RuntimeError, 'stinky things happen'
      end
    end

    context 'with no params' do
      let(:message) { 'hello' }

      it 'logs the block result for Rails.logger.info { block }' do
        expect(logger).to receive(:info).with %({"msg":"#{message}","log_timestamp":"#{timestamp}","log_level":"info"})
        described_class.info { message }
      end
    end

    context 'trims white space' do
      let(:message) { "  b y \n\n " }
      let(:expected) { 'b y' }

      it 'trims and logs the block result for Rails.logger.info { block }' do
        expect(logger).to receive(:info).with %({"msg":"#{expected}","log_timestamp":"#{timestamp}","log_level":"info"})
        described_class.info { message }
      end
    end
  end

  describe 'include specific params from the request' do
    let(:log_msg) do
      {
        msg: message,
        log_timestamp: timestamp,
        log_level: log_level,
        msn: 'log this',
        session_token: 'log this',
        request_id: 'log this',
        ip: 'log this',
        endpoint: 'log this',
        client_id: 'log this',
        phone_id: 'log this'
      }.to_json
    end

    before do
      [:msn, :session_token, :request_id, :ip, :endpoint,
       :client_id, :phone_id].each do |k|
        described_class.log_context[k] = 'log this'
      end
    end

    it 'logs the specified parameters' do
      expect(logger).to receive(:info).with log_msg
      described_class.info msg: message
    end
  end

  describe 'includes details from an exception' do
    let(:msg) { 'unknown error' }
    let(:exception_message) { 'An unexpected oops occurred' }
    let(:exception) { Exception.new(exception_message) }
    let(:exception_backtrace) { %w(a b) }
    let(:exception_class) { exception.class.name }

    before do
      allow(exception).to receive(:backtrace).and_return(exception_backtrace)
      allow(exception).to receive(:message).and_return(exception_message)
    end

    context 'with msg' do
      let(:log_msg) do
        {
          msg: msg,
          log_timestamp: timestamp,
          log_level: 'error',
          exception_class: exception_class,
          exception_message: exception_message,
          exception_backtrace: exception_backtrace.join('\n')
        }.to_json
      end

      it 'logs error details for exceptions' do
        expect(logger).to receive(:error).with(log_msg)
        described_class.error msg: msg, exception: exception
      end
    end

    context 'override null msg' do
      let(:log_msg) do
        {
          msg: exception_message,
          log_timestamp: timestamp,
          log_level: 'error',
          exception_class: exception_class,
          exception_message: exception_message,
          exception_backtrace: exception_backtrace.join('\n')
        }.to_json
      end

      it 'logs error details for exceptions' do
        expect(logger).to receive(:error).with(log_msg)
        described_class.error exception: exception
      end
    end
  end
end
