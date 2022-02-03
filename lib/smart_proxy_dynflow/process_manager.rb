module Proxy
  module Dynflow
    class IOBuffer
      attr_accessor :io
      attr_reader :buffer
      def initialize(io)
        @buffer = ''
        @io = io
      end

      def on_data(&block)
        @callback = block
      end

      def to_io
        @io
      end

      def to_s
        @buffer
      end

      def empty?
        @buffer.empty?
      end

      def closed?
        @io.closed?
      end

      def close
        @io.close unless @io.closed?
      end

      def read_available!
        data = ''
        loop { data += @io.read_nonblock(4096) }
      rescue IO::WaitReadable # rubocop:disable Lint/HandleExceptions
      rescue EOFError
        close
      ensure
        @buffer += with_callback(data) unless data.empty?
      end

      def write_available!
        until @buffer.empty?
          n = @io.write_nonblock(@buffer)
          @buffer = @buffer[n..-1]
        end
      rescue IO::WaitWritable # rubocop:disable Lint/HandleExceptions
      rescue EOFError
        close
      end

      def add_data(data)
        @buffer += data
      end

      private

      def with_callback(data)
        if @callback
          @callback.call(data)
        else
          data
        end
      end
    end

    class ProcessManager
      attr_reader :stdin, :stdout, :stderr, :pid, :status
      def initialize(command)
        @command = command
        @stdin  = IOBuffer.new(nil)
        @stdout = IOBuffer.new(nil)
        @stderr = IOBuffer.new(nil)
      end

      def run!
        start! unless started?
        process until done?
        self
      end

      def start!
        in_read,  in_write  = IO.pipe
        out_read, out_write = IO.pipe
        err_read, err_write = IO.pipe

        @pid = spawn(*@command, :in => in_read, :out => out_write, :err => err_write)
        [in_read, out_write, err_write].each(&:close)

        @stdin.io  = in_write
        @stdout.io = out_read
        @stderr.io = err_read
      rescue Errno::ENOENT => e
        @pid = -1
        @status = 255
        @stderr.add_data(e.message)
      end

      def started?
        !pid.nil?
      end

      def done?
        started? && !status.nil?
      end

      def close
        [@stdin, @stdout, @stderr].each(&:close)
      end

      def process(timeout: nil)
        writers = [@stdin].reject { |buf| buf.empty? || buf.closed? }
        readers = [@stdout, @stderr].reject(&:closed?)

        if readers.empty? && writers.empty?
          finish
          return
        end

        ready_readers, ready_writers = IO.select(readers, writers, nil, timeout)
        (ready_readers || []).each(&:read_available!)
        (ready_writers || []).each(&:write_available!)
      end

      def finish
        close
        Process.wait(@pid)
        @status = $CHILD_STATUS.exitstatus
      end

      def on_stdout(&block)
        @stdout.on_data(&block)
      end

      def on_stderr(&block)
        @stderr.on_data(&block)
      end
    end
  end
end
