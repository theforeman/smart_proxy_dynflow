module SmartProxyDynflowCore
  class LoggerMiddleware
    def initialize(app)
      @logger = SmartProxyDynflowCore::Log.instance
      @app = app
    end

    def call(env)
      before = Time.now.to_f
      status = 500
      env['rack.logger'] = @logger
      @logger.info { "Started #{env['REQUEST_METHOD']} #{env['PATH_INFO']} #{env['QUERY_STRING']}" }
      @logger.debug { 'Headers: ' + env.select { |k, v| k.start_with? 'HTTP_' }.inspect }
      if @logger.debug? && env['rack.input']
        body = env['rack.input'].read
        @logger.debug body.empty? ? '' : 'Body: ' + body
        env['rack.input'].rewind
      end
      status, = @app.call(env)
    rescue Exception => e
      Log.exception "Error processing request '#{::Logging.mdc['request']}", e
      raise e
    ensure
      @logger.info do
        after = Time.now.to_f
        duration = (after - before) * 1000
        "Finished #{env['REQUEST_METHOD']} #{env['PATH_INFO']} with #{status} (#{duration.round(2)} ms)"
      end
    end
  end
end
