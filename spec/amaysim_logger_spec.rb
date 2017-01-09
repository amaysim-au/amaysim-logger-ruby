require 'active_support'
require 'timecop'
require 'request_store'

# rubocop:disable RSpec/MessageSpies
RSpec.describe AmaysimLogger do
  let(:logger) { described_class.logger }
  let(:start_time) { DateTime.parse('2016-01-22 15:46:22 +1100') }
  let(:end_time) { DateTime.parse('2016-01-22 15:46:32 +1100') }
  let(:log_timestamp) { start_time }
  before do
    Timecop.freeze(start_time)
    RequestStore.store[:log_append] = nil
  end

  describe '.append_to_log' do
    context 'when RequestStore[:log_append] is not a hash' do
      it 'sets RequestStore[:log_append] as-is' do
        foo = Object.new
        RequestStore[:log_append] = :whatever
        described_class.append_to_log(foo)
        expect(RequestStore[:log_append]).to eq(foo)
      end
    end

    context 'when RequestStore[:log_append] is a hash' do
      it 'merges the given hash into RequestStore[:log_append]' do
        RequestStore[:log_append] = { foo: :bar }
        described_class.append_to_log(bar: :baz)
        expect(RequestStore[:log_append]).to eq(foo: :bar, bar: :baz)
      end
    end
  end

  context 'without a block' do
    let(:log_msg) do
      {
        msg: 'my_message',
        log_timestamp: '2016-01-22 15:46:22 +1100 AEDT'
      }.to_json
    end

    it 'logs info messages' do
      expect(logger).to receive(:info).with log_msg
      described_class.info msg: 'my_message'
    end

    it 'logs debug messages' do
      expect(logger).to receive(:debug).with log_msg
      described_class.debug msg: 'my_message'
    end

    it 'logs warn messages' do
      expect(logger).to receive(:warn).with log_msg
      described_class.warn msg: 'my_message'
    end

    it 'logs error messages' do
      expect(logger).to receive(:error).with log_msg
      described_class.error msg: 'my_message'
    end
  end

  describe 'with a block' do
    let(:start_log_msg) do
      {
        msg: 'my_message',
        log_timestamp: '2016-01-22 15:46:22 +1100 AEDT',
        start_time: '2016-01-22 15:46:22 +1100 AEDT'
      }.to_json
    end
    let(:end_log_msg) do
      {
        msg: 'my_message',
        log_timestamp: '2016-01-22 15:46:22 +1100 AEDT',
        start_time: '2016-01-22 15:46:22 +1100 AEDT',
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
        described_class.info(msg: 'my_message', execute: lambda do
          Timecop.freeze(end_time)
        end)
      end

      it 'logs the end time and duration' do
        expect(logger).to receive(:info).with end_log_msg
      end

      it 'returns the block return' do
        expect(
          described_class.info(msg: 'my_message', execute: lambda do
            block_return_msg
          end)
        ).to eq block_return_msg
      end
    end

    context 'with exception' do
      let(:end_log_msg) do
        {
          msg: 'my_message',
          log_timestamp: '2016-01-22 15:46:22 +1100 AEDT',
          start_time: '2016-01-22 15:46:22 +1100 AEDT',
          exception: 'RuntimeError',
          exception_msg: 'stinky things happen',
          end_time: '2016-01-22 15:46:32 +1100 AEDT',
          duration: 10.0
        }.to_json
      end

      let(:stinky_thing) do
        described_class.info(msg: 'my_message', execute: lambda do
          Timecop.freeze(end_time)
          raise 'stinky things happen'
        end)
      end

      it 'logs start_log_msg on exception' do
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
  end

  describe 'include specific params from the request' do
    let(:log_msg) do
      {
        msg: 'my_message',
        log_timestamp: '2016-01-22 15:46:22 +1100 AEDT',
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
      RequestStore.store[:log_append] = {}
      [:msn, :session_token, :request_id, :ip, :endpoint,
       :client_id, :phone_id].each do |k|
        RequestStore.store[:log_append][k] = 'log this'
      end
    end

    it 'logs the specified parameters' do
      expect(logger).to receive(:info).with log_msg
      described_class.info msg: 'my_message'
    end
  end
end
