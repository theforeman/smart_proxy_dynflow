require 'test_helper'

module SmartProxyDynflowCore
  class TaskLauncherRegistryTest < MiniTest::Spec
    describe TaskLauncherRegistry do
      let(:registry) { TaskLauncherRegistry }

      before do
        registry.stubs(:registry).returns({})
      end

      describe '#register' do
        it 'can register launchers' do
          registry.register('my_feature', Integer)
          registry.send(:registry).must_equal({ 'my_feature' => Integer })
        end
      end

      describe '#fetch' do
        it 'raises when key not found' do
          proc { registry.fetch('missing') }.must_raise KeyError
        end

        it 'provides a default value' do
          default = 'default'
          registry.fetch('missing', default).must_equal default
        end

        it 'fetches the value' do
          registry.expects(:registry).returns({'my_feature' => Integer})
          registry.fetch('my_feature').must_equal Integer
        end
      end

      describe '#key' do
        it 'checks presence of a key' do
          registry.expects(:registry).returns({'my_feature' => Integer}).twice
          assert registry.key?('my_feature')
          refute registry.key?('missing')
        end
      end

      describe '#features' do
        it 'provides a list of features' do
          registry.register('foo', nil)
          registry.register('bar', nil)
          registry.register('baz', nil)
          registry.features.must_equal %w(foo bar baz)
        end
      end
    end
  end
end
