module Proxy
  module Dynflow
    # A buffer around an IO object providing buffering and convenience methods
    # for non-blocking reads and writes.
    #
    # @note Using a single IOBuffer with a single IO for both reads and writes might not be a good idea. If you need to use a single IO for both reads and writes, wrap it in two separate IOBuffers.
    #
    # @attr_accessor [IO] io The IO which the buffer wraps
    # @attr_reader [String] buffer The buffer where the data read from the underlying IO is buffered
    class IOBuffer
      attr_accessor :io
      attr_reader :buffer

      # @param [IO] io The IO object to be buffered
      def initialize(io)
        @buffer = ''
        @io = io
      end

      # Sets a callback to be executed each time data is read from the
      # underlying IO.
      #
      # @note Note that if the callback is provided, the buffer will store the return value of the callback instead of the raw data.
      #
      # @yieldparam [String] data read from the underlying IO
      # @yieldreturn [String] data to be buffered
      # @return [void]
      def on_data(&block)
        @callback = block
      end

      # Exposes the underlying IO so that the buffer itself can be used in IO.select calls.
      #
      # @return [IO] the underlying IO
      def to_io
        @io
      end

      # Exposes the contents of the buffer as a String
      #
      # @return [String] the buffered data
      def to_s
        @buffer
      end

      # Checks whether the buffer is empty
      #
      # @return [true, false] whether the buffer is empty
      def empty?
        @buffer.empty?
      end

      # Checks whether the underlying IO is empty
      #
      # @return [true, false] whether the underlying IO is empty
      def closed?
        @io.closed?
      end

      # Closes the underlying IO. Does nothing if the IO is already closed.
      #
      # @return [void]
      def close
        @io.close unless @io.closed?
      end

      # Reads all the data that is currently waiting in the IO and stores it. If
      # EOFError is encountered during the read, the underlying IO is closed.
      #
      # @return [void]
      def read_available!
        data = ''
        loop { data += @io.read_nonblock(4096) }
      rescue IO::WaitReadable # rubocop:disable Lint/HandleExceptions
      rescue EOFError
        close
      ensure
        @buffer += with_callback(data) unless data.empty?
      end

      # Writes all the data into the IO that can be written without blocking. It
      # is a no-op if there are no data to be written. If an EOFError is
      # encountered during the write, the underlying IO is closed.
      #
      # @return [void]
      def write_available!
        until @buffer.empty?
          n = @io.write_nonblock(@buffer)
          @buffer = @buffer[n..-1]
        end
      rescue IO::WaitWritable # rubocop:disable Lint/HandleExceptions
      rescue EOFError
        close
      end

      # Adds data to the buffer. If the buffer is used for writing, then this
      # should be the preferred method of queueing the data to be written.
      #
      # @return [void]
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

    # An abstraction for managing local processes.
    #
    # It can be used to:
    # - spawn a local process
    # - track its lifecycle
    # - communicate with it through its standard input, output and error
    # - step through the execution one event at a time or start the child process and wait until it finishes
    #
    # @example Run date command and collect its output
    #   pm = ProcessManager.new('date')
    #   pm.run!
    #   pm.status #=> 0
    #   pm.stdout.to_s.chomp #=> "Thu Feb  3 04:27:42 PM CET 2022"
    #
    # @example Run a shell loop, outputting all the lines it generates
    #   pm = ProcessManager.new(['/bin/sh', '-c', 'for i in 1 2 3; do echo $i; sleep 1; done'])
    #   pm.on_stdout { |data| puts data; '' }
    #   pm.run!
    #   #=> 1
    #   #=> 2
    #   #=> 3
    #
    # @example Run bc (calculator) interactively and count down from 10 to 0
    #   pm = ProcessManager.new('bc')
    #   pm.on_stdout do |data|
    #     if data.match?(/^\d+/)
    #       n = data.to_i
    #       if n.zero?
    #         pm.stdin.to_io.close
    #       else
    #         pm.stdin.add_data("#{n} - 1\n")
    #       end
    #     end
    #     data
    #   end
    #   pm.stdin.add_data("10\n")
    #   pm.run!
    #   pm.stdout.to_s.lines #=. ["10\n", "9\n", "8\n", "7\n", "6\n", "5\n", "4\n", "3\n", "2\n", "1\n", "0\n"]
    #
    # @attr_reader [Proxy::Dynflow::IOBuffer] stdin IOBuffer buffering writes to child process' standard input
    # @attr_reader [Proxy::Dynflow::IOBuffer] stdout IOBuffer buffering reads from child process' standard output
    # @attr_reader [Proxy::Dynflow::IOBuffer] stderr IOBuffer buffering reads from child process' standard error
    # @attr_reader [nil, Integer] pid Process id of the child process, nil if the process was not started yet, -1 if the process could not be started
    # @attr_reader [nil, Integer] status Exit status of the child process. nil if the child process has not finished yet, 255 if the process could not be started
    class ProcessManager
      attr_reader :stdin, :stdout, :stderr, :pid, :status

      # @param [String, [String], [Hash, String]] command A command to run in one of the forms accepted by Kernel.spawn
      def initialize(command)
        @command = command
        @stdin  = IOBuffer.new(nil)
        @stdout = IOBuffer.new(nil)
        @stderr = IOBuffer.new(nil)
      end

      # Starts the process manager and runs it until it finishes
      #
      # @return [ProcessManager] the process manager itself to allow method chaining
      def run!
        start! unless started?
        process until done?
        self
      end

      # Starts the child process. It creates 3 pipes for communicating with the
      # child process and the forks it. The process manager is considered done
      # if the child process cannot be started.
      #
      # @return [void]
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
        [in_read, in_write, out_read, out_write, err_read, err_write].each(&:close)
        @pid = -1
        @status = 255
        @stderr.add_data(e.message)
      end

      # Determines whether the process manager already forked off its child process
      #
      # @return [true, false] whether the process manager already forked off its child process
      def started?
        !pid.nil?
      end

      # Determines whether the child process of the process manager already finished
      #
      # @return [true, false] whether the child process of the process manager already finished
      def done?
        started? && !status.nil?
      end

      # Runs a single iteration of the manager's processing loop. It waits until either:
      # - data is available in pipes connected to the child process' standard output or error
      # - there is pending data to be written and the pipe connected to the child process' standard input is writable
      # - a timeout is reached
      #
      # After the wait, all pending data is read and written.
      #
      # If all the pipes connected to the child process are closed, it marks the
      # execution as complete and performs cleanup.
      #
      # @param timeout [nil, Numeric] controls how long this call should wait for data to become available. Waits indefinitely if nil.
      # @return [void]
      def process(timeout: nil)
        raise 'Cannot process until the manager is started' unless started?
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

      # Sets block to be executed each time data is read from child process' standard output
      #
      # @return [void]
      def on_stdout(&block)
        @stdout.on_data(&block)
      end

      # Sets block to be executed each time data is read from child process' standard error
      #
      # @return [void]
      def on_stderr(&block)
        @stderr.on_data(&block)
      end

      private

      # Makes the process manager close all the pipes it may have opened to communicate with the child process
      #
      # @return [void]
      def close
        [@stdin, @stdout, @stderr].each(&:close)
      end

      # Makes the process manager finish its run, closing opened FDs and reaping the child process
      #
      # @return [void]
      def finish
        close
        _pid, status = Process.wait2(@pid)
        @status = status.exitstatus
      end
    end
  end
end
