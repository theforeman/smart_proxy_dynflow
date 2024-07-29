# frozen_string_literal: true

module Proxy::Dynflow
  class ContinuousOutput
    attr_accessor :raw_outputs

    def initialize(raw_outputs = [])
      @raw_outputs = []
      raw_outputs.each { |raw_output| add_raw_output(raw_output) }
    end

    def add_raw_output(raw_output)
      missing_args = %w[output_type output timestamp] - raw_output.keys
      unless missing_args.empty?
        raise ArgumentError, "Missing args for raw output: #{missing_args.inspect}"
      end

      @raw_outputs << raw_output
    end

    def empty?
      @raw_outputs.empty?
    end

    def last_timestamp
      return if @raw_outputs.empty?

      @raw_outputs.last.fetch('timestamp')
    end

    def sort!
      @raw_outputs.sort_by! { |record| record['timestamp'].to_f }
    end

    def humanize
      sort!
      raw_outputs.map { |output| output['output'] }.join("\n")
    end

    def add_exception(context, exception, timestamp: Time.now.getlocal, id: nil)
      add_output(context + ": #{exception.class} - #{exception.message}", 'debug', timestamp: timestamp, id: id)
    end

    def add_output(...)
      add_raw_output(self.class.format_output(...))
    end

    def self.format_output(message, type = 'debug', timestamp: Time.now.getlocal, id: nil)
      base = { 'output_type' => type,
               'output' => message,
               'timestamp' => timestamp.to_f }
      base['id'] = id if id
      base
    end
  end
end
