RSpec.describe AmaysimLogger do
  describe '.logger' do
    specify do
      expect(described_class.logger).to be_instance_of(AmaysimLogger::Logger)
    end
  end
end
