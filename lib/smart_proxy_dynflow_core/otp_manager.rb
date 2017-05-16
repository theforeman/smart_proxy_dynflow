require 'base64'
require 'securerandom'

module SmartProxyDynflowCore
  class OtpManager
    class << self
      def get_otp(username)
        otp = SecureRandom.hex
        Settings.instance.tokens << tokenize(username, otp)
        otp
      end

      def drop_otp(username, password)
        SmartProxyDynflowCore::Settings.instance.tokens.delete tokenize(username, password)
      end

      private

      def tokenize(username, password)
        Base64.strict_encode64("#{username}:#{password}")
      end
    end
  end
end
