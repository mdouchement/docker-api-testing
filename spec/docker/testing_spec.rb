require 'spec_helper'

module Docker
  describe Testing do
    after(:all) do
      Testing.fake!
    end

    describe '.disable!' do
      it 'changes the test mode' do
        Testing.fake!
        expect { Testing.disable! }.to change { Testing.__test_mode }.to(:disable)
      end
    end

    describe '.disable?' do
      it 'tests if the mode is activated' do
        Testing.disable!
        expect(Testing.disable?).to be(true)
      end
    end

    describe '.disable!' do
      it 'changes the test mode' do
        Testing.disable!
        expect { Testing.fake! }.to change { Testing.__test_mode }.to(:fake)
      end
    end

    describe '.disable?' do
      it 'tests if the mode is activated' do
        Testing.fake!
        expect(Testing.fake?).to be(true)
      end
    end

    describe '.time_now' do
      it 'returns the curent time well formatted' do
        expect(Testing.time_now).to match(/\d+\-\d+\-\w+:\d+:\d+\.\d+Z/)
      end
    end
  end
end
