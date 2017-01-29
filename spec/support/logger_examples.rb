require 'timecop'

RSpec.shared_examples 'logging' do |level_method, level|
  class TestException < StandardError
    def backtrace
      %w(line1 line2 line3)
    end
  end

  let(:output) { StringIO.new }
  let(:logger) { AmaysimLogger::Logger.new(output) }

  let(:start_time) { DateTime.parse('2016-01-22 15:46:22.0000 +1100') }
  let(:start_timestamp) { '2016-01-22 15:46:22 +1100 AEDT' }

  let(:end_time) { DateTime.parse('2016-01-22 15:46:32.5000 +1100') }
  let(:end_timestamp) { '2016-01-22 15:46:32 +1100 AEDT' }

  let(:log_json) { JSON.parse(output.string.split("\n").first) }

  before do
    Timecop.freeze(start_time)
    output.truncate(0)
  end

  describe ".#{level_method}" do
    it "logs a simple string message at #{level} level" do
      logger.send(level_method, 'test')

      expect(log_json).to eq(
        'level' => level,
        'log_timestamp' => start_timestamp,
        'msg' => 'test'
      )
    end

    it "logs a hash with msg string message at #{level} level" do
      logger.send(level_method, msg: 'test')

      expect(log_json).to eq(
        'level' => level,
        'log_timestamp' => start_timestamp,
        'msg' => 'test'
      )
    end

    it "logs a hash with additional params at #{level} level" do
      logger.send(level_method, msg: 'test', other: 'foobar')

      expect(log_json).to eq(
        'level' => level,
        'log_timestamp' => start_timestamp,
        'msg' => 'test',
        'other' => 'foobar'
      )
    end

    it "logs a simple string message and times a block at #{level} level" do
      logger.send(level_method, 'test') { Timecop.freeze(end_time) }

      expect(log_json).to eq(
        'duration' => 10.5,
        'end_time' => end_timestamp,
        'level' => level,
        'log_timestamp' => end_timestamp,
        'start_time' => start_timestamp,
        'msg' => 'test'
      )
    end

    it "logs a hash with additional params and times a block at #{level} level" do
      logger.send(level_method, msg: 'something', other: 'foobar') do
        Timecop.freeze(end_time)
      end

      expect(log_json).to eq(
        'duration' => 10.5,
        'end_time' => end_timestamp,
        'level' => level,
        'log_timestamp' => end_timestamp,
        'start_time' => start_timestamp,
        'msg' => 'something',
        'other' => 'foobar'
      )
    end

    it "logs a logs an exeption from within a block #{level} level" do
      expect do
        logger.send(level_method, msg: 'something', other: 'foobar') do
          raise TestException, 'Oh no'
        end
      end.to raise_error(TestException)

      expect(log_json).to eq(
        'duration' => 0.0,
        'end_time' => start_timestamp,
        'exception' => 'TestException',
        'exception_backtrace' => "line1\nline2\nline3",
        'exception_msg' => 'Oh no',
        'level' => level,
        'log_timestamp' => start_timestamp,
        'start_time' => start_timestamp,
        'msg' => 'something',
        'other' => 'foobar'
      )
    end
  end
end
