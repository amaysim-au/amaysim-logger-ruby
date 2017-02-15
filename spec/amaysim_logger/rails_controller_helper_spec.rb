require 'amaysim_logger/rails_controller_helper'
require 'action_controller'

# rubocop:disable RSpec/MessageSpies
# rubocop:disable RSpec/VerifiedDoubles
class AmaysimLogger
  class TestController < ActionController::Base
    include RailsControllerHelper
  end

  RSpec.describe RailsControllerHelper do
    let(:logger) { AmaysimLogger.logger }
    let(:controller) { TestController.new }
    let(:request) { double('request') }
    let(:start_time) { '2016-01-22 15:46:22 +1100 AEDT' }
    let(:end_time) { '2016-01-22 15:46:32 +1100 AEDT' }

    before do
      allow(request).to receive(:uuid).and_return('uuid')
      allow(request).to receive(:remote_ip).and_return('1.2.3.4')
      allow(request).to receive(:headers).and_return('HTTP_USER_AGENT' => 'Chrome')
      allow(request).to receive(:url).and_return('http://amaysim.com.au')
      controller.request = request
      Timecop.freeze(DateTime.parse(start_time))
    end

    describe '#log_request' do
      context 'when correlation-id not provided by HTTP header' do
        before do
          allow(SecureRandom).to receive(:uuid).and_return('generated-uuid')
        end

        # rubocop:disable RSpec/ExampleLength
        it 'logs the http request with a generated correlation id' do
          log = {
            msg: 'Web request',
            log_timestamp: start_time,
            log_level: 'debug',
            request_id: 'uuid',
            ip: '1.2.3.4',
            user_agent: 'Chrome',
            endpoint: 'http://amaysim.com.au',
            correlation_id: 'generated-uuid',
            start_time: start_time,
            end_time: end_time,
            duration: 10.0
          }.to_json
          expect(logger).to receive(:debug).with(log)
          controller.log_request { Timecop.freeze(DateTime.parse(end_time)) }
        end
      end

      context 'when correlation-id provided by HTTP header' do
        before do
          allow(request).to receive(:headers).and_return(
            'HTTP_USER_AGENT' => 'Chrome',
            'CORRELATION-ID' => 'provided-uuid'
          )
        end

        it 'logs the http request with the provided correlation id' do
          log = {
            msg: 'Web request',
            log_timestamp: start_time,
            log_level: 'debug',
            request_id: 'uuid',
            ip: '1.2.3.4',
            user_agent: 'Chrome',
            endpoint: 'http://amaysim.com.au',
            correlation_id: 'provided-uuid',
            start_time: start_time,
            end_time: end_time,
            duration: 10.0
          }.to_json
          expect(logger).to receive(:debug).with(log)
          controller.log_request { Timecop.freeze(DateTime.parse(end_time)) }
        end
      end
    end
  end
end
