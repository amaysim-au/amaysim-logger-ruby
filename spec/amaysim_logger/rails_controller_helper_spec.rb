RSpec.describe AmaysimLogger::RailsControllerHelper do
  include described_class
  let(:output) { StringIO.new }
  let(:logger) { AmaysimLogger::Logger.new(output) }

  before do
    AmaysimLogger.logger = logger
    AmaysimLogger.log_context = {}
  end

  describe '.add_to_log_context' do
    it 'adds the input to the log context' do
      add_to_log_context(foo: :bar)
      expect(logger.log_context).to eq(foo: :bar)
    end
  end
end
