RSpec.describe AmaysimLogger do
  describe '::VERSION' do
    it 'exists as a string' do
      expect(AmaysimLogger::VERSION).to be_instance_of(String)
    end
  end
end
