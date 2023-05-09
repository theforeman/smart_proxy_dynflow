require 'test_helper'
require 'smart_proxy_dynflow/io_buffer'
require 'ostruct'

module Proxy::Dynflow
  class IOBufferTest
    describe IOBuffer do
      let(:buffer) { IOBuffer.new(StringIO.new) }

      it 'is empty by default' do
        assert_predicate buffer, :empty?
        assert_equal('', buffer.buffer)
      end

      describe '#on_data' do
        it 'is noop by default' do
          assert_equal('hello', buffer.send(:with_callback, 'hello'))
        end

        it 'allows setting a callback' do
          buffer.on_data { |data| "|#{data}|" }
          assert_equal('|hello|', buffer.send(:with_callback, 'hello'))
        end
      end

      describe '#closed?' do
        it 'passes it to the underlying IO' do
          io = mock
          io.expects(:closed?)
          buffer.io = io
          buffer.closed?
        end
      end

      describe '#write_available!' do
        it 'is a noop with empty buffer' do
          buffer.io.expects(:write_nonblock).never
          buffer.write_available!
        end

        it 'closes itself on EOF' do
          buffer.add_data('hello')
          buffer.io.expects(:write_nonblock).with('hello').raises(EOFError)
          buffer.write_available!
          assert_predicate buffer, :closed?
        end

        # IO::WaitWritable is a module so mocha refuses to raise it and we have
        # to derive a custom exception class
        class CustomWaitWritable < RuntimeError
          include IO::WaitWritable
        end

        it 'exits on IO::WaitWritable' do
          buffer.add_data('hello')
          buffer.io.expects(:write_nonblock).with('hello').returns(1)
          buffer.io.expects(:write_nonblock).with('ello').raises(CustomWaitWritable)
          buffer.write_available!
          assert_equal('ello', buffer.to_s)
        end
      end

      describe '#read_available!' do
        # IO::WaitReadable is a module so mocha refuses to raise it and we have to
        # derive a custom exception class
        class CustomWaitReadable < RuntimeError
          include IO::WaitReadable
        end

        it 'closes itself on EOF' do
          buffer.io.expects(:read_nonblock).raises(EOFError)
          buffer.read_available!
          assert_predicate buffer, :closed?
        end

        it 'exits on IO::WaitReadable' do
          buffer.io.expects(:read_nonblock).times(3).returns('hello, ', 'friend').then.raises(CustomWaitReadable)
          buffer.read_available!
          assert_equal('hello, friend', buffer.to_s)
        end

        it 'does not call the callback if there are no data' do
          target = mock
          target.expects(:hit).never
          buffer.on_data { |data| target.hit(data); data } # rubocop:disable Style/Semicolon
          buffer.io.expects(:read_nonblock).raises(CustomWaitReadable)
          buffer.read_available!
        end

        it 'calls the callback with data' do
          target = mock
          buffer.on_data { |data| target.hit(data); data } # rubocop:disable Style/Semicolon
          # The read chunks are concatenated before calling the callback
          target.expects(:hit).with('hello, friend')
          buffer.io.expects(:read_nonblock).times(3).returns('hello, ', 'friend').then.raises(CustomWaitReadable)
          buffer.read_available!
        end

        it 'stores the result of the callback instead of raw data' do
          buffer.on_data { |data| "|#{data}|" }
          buffer.io.expects(:read_nonblock).times(3).returns('hello, ', 'friend').then.raises(CustomWaitReadable)
          buffer.read_available!
          assert_equal('|hello, friend|', buffer.to_s)
        end
      end
    end
  end
end
