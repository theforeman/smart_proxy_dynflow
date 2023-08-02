# frozen_string_literal: true

require 'test_helper'
require 'smart_proxy_dynflow/process_manager'
require 'ostruct'

module Proxy::Dynflow
  class ProcessManagerTest
    describe ProcessManager do
      let(:pm) { ProcessManager.new(command) }

      describe 'general behavior' do
        it 'can be controlled manually' do
          pm = ProcessManager.new('true')
          refute pm.started?
          refute pm.done?

          pm.start!
          assert pm.started?
          refute pm.done?

          pm.process
          pm.process
          assert pm.started?
          assert pm.done?
          assert_equal pm.status, 0
        end

        it 'can be run' do
          pm = ProcessManager.new('true')
          refute pm.started?
          refute pm.done?

          pm.run!

          assert pm.started?
          assert pm.done?
          assert_equal pm.status, 0
        end

        it 'captures stdout' do
          pm = ProcessManager.new('echo hello')
          pm.run!
          assert_equal pm.stderr.to_s, ''
          assert_equal pm.stdout.to_s.chomp, 'hello'
        end

        it 'captures stderr' do
          pm = ProcessManager.new('echo hello >&2')
          pm.run!
          assert_equal pm.stderr.to_s.chomp, 'hello'
          assert_equal pm.stdout.to_s, ''
        end

        it 'captures exit code' do
          pm = ProcessManager.new('exit 5')
          pm.run!
          assert_equal pm.status, 5
        end

        it 'can be hooked onto stdout' do
          target = mock
          target.expects(:hit).with("hello\n")

          pm = ProcessManager.new('echo hello')
          pm.on_stdout { |data| target.hit(data); data } # rubocop:disable Style/Semicolon
          pm.run!
        end

        it 'can be hooked onto stderr' do
          target = mock
          target.expects(:hit).with("hello\n")

          pm = ProcessManager.new('echo hello >&2')
          pm.on_stderr { |data| target.hit(data); data } # rubocop:disable Style/Semicolon
          pm.run!
        end

        it 'can write stdin' do
          pm = ProcessManager.new('bc')
          pm.on_stdout do |data|
            if data.match?(/^\d+/)
              n = data.to_i
              if n.zero?
                pm.stdin.to_io.close
              else
                pm.stdin.add_data("#{n} - 1\n")
              end
            end
            data
          end
          pm.stdin.add_data("10\n")
          pm.run!
          assert_equal pm.stdout.to_s.lines.map(&:chomp), %w[10 9 8 7 6 5 4 3 2 1 0]
        end
      end

      describe '#process' do
        it 'accepts a timeout' do
          pm = ProcessManager.new('cat')
          pm.start!
          pm.process(timeout: 0.1) # Nothing happens
          assert pm.started?
          refute pm.done?
          assert_equal pm.stdout.to_s, ''
          pm.stdin.add_data("hello\n")
          pm.process(timeout: 0.1) # Stdin gets written
          pm.process(timeout: 0.1) # Stdout gets read
          pm.stdin.to_io.close
          pm.process(timeout: 0.1) # Stdout and stderr get closed
          refute pm.done?
          pm.process(timeout: 0.1) # It determines there is nothing left to be done and finishes
          assert pm.done?
        end

        it 'raises an exception when called before start!' do
          assert_raises { ProcessManager.new('').process }
        end
      end

      describe '#close' do
        it 'closes the ends which are not passed to the child' do
          pm = ProcessManager.new('true')
          pm.stdin.io = StringIO.new
          pm.stdout.io = StringIO.new
          pm.stderr.io = StringIO.new

          pm.close

          assert pm.stdin.closed?
          assert pm.stdout.closed?
          assert pm.stderr.closed?
        end
      end

      describe '#finish' do
        it 'reaps the managed process' do
          pid = 1024
          status = OpenStruct.new(exitstatus: 12)

          pipe_end = mock
          pm = ProcessManager.new('true')
          pm.expects(:spawn).returns(pid)
          IO.expects(:pipe).times(3).returns([pipe_end, pipe_end])
          # 3 of the pipes are closed after #spawn
          pipe_end.expects(:close).times(3)
          Process.expects(:wait2).with(pid).returns([pid, status])
          pm.expects(:close)

          pm.start!
          pm.send(:finish)

          assert_equal pm.pid, pid
          assert_equal pm.status, status.exitstatus
        end

        it 'is a noop when called on a stopped process' do
          pm = ProcessManager.new('true')
          pm.run!
          assert pm.started?
          assert pm.done?
          pm.send(:finish)
        end
      end

      describe 'Errno::ENOENT handling' do
        let(:command) { 'definitely-not-a-valid-command' }

        it 'closes all pipes' do
          pipe_end = File.open('/dev/null', 'r')
          IO.expects(:pipe).times(3).returns([pipe_end, pipe_end])
          pipe_end.expects(:close).times(6)

          pm.run!

          # Cleanup
          IO.for_fd(pipe_end.to_i).close
        end

        it 'represents the failure correctly' do
          pm.run!
          assert_equal pm.pid, -1
          assert_equal pm.status, 255
          assert_equal pm.stderr.to_s, "No such file or directory - #{command}"
        end

        it 'represents the failure correctly' do
          pm.start!
          pm.process(timeout: 0.1)

          assert_equal pm.pid, -1
          assert_equal pm.status, 255
          assert_equal pm.stderr.to_s, "No such file or directory - #{command}"
        end
      end
    end
  end
end
