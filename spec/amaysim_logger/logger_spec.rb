RSpec.describe AmaysimLogger do
  describe Logger do
    include_examples 'logging', :info, 'INFO'
    include_examples 'logging', :debug, 'DEBUG'
    include_examples 'logging', :warn, 'WARN'
    include_examples 'logging', :error, 'ERROR'
    include_examples 'logging', :unknown, 'ANY'

    describe '.add_to_log_context' do
      let(:output) { StringIO.new }
      let(:logger) { AmaysimLogger::Logger.new(output) }

      it 'adds the input to the log context' do
        logger.add_to_log_context(foo: :bar)
        expect(logger.log_context).to eq(foo: :bar)
      end

      it 'merges with the current log context' do
        logger.log_context = { bar: :baz }
        logger.add_to_log_context(foo: :bar)
        expect(logger.log_context).to eq(bar: :baz, foo: :bar)
      end

      it 'works with strings' do
        logger.add_to_log_context('foobar')
        expect(logger.log_context).to eq(data: 'foobar')
      end
    end
  end
end
