# frozen_string_literal: true

require 'test_helper'
require 'smart_proxy_dynflow/otp_manager'

module Proxy::Dynflow
  class OtpManagerTest < Minitest::Spec
    class TestOtpManager < OtpManager
      def self.reset!
        @passwords = nil
      end
    end

    def try_to_authenticate(username, password)
      TestOtpManager.authenticate(OtpManager.tokenize(username, password))
    end

    before do
      TestOtpManager.reset!
    end

    let(:username) { 'myuser' }
    let(:password) { '123456789' }
    let(:base64)   { 'bXl1c2VyOjEyMzQ1Njc4OQ==' }

    it 'it doesn\'t raise when no passwords were generated yet' do
      refute try_to_authenticate('missing', 'password')
    end

    it 'generates OTPs using SecureRandom.hex and converts them to strings' do
      otp = 4
      SecureRandom.stubs(:hex).returns(otp)
      _(TestOtpManager.generate_otp(username)).must_equal otp.to_s
    end

    it 'provides #drop_otp method that removes OTP only when correct username and password is provided' do
      otp = TestOtpManager.generate_otp(username)
      refute TestOtpManager.drop_otp('wrong_username', 'wrong_password')
      refute TestOtpManager.drop_otp(username, 'wrong_password')
      refute TestOtpManager.drop_otp('wrong_username', otp)
      assert TestOtpManager.drop_otp(username, otp)
    end

    it 'authenticate removes OTP only when correct username and password is provided' do
      otp = TestOtpManager.generate_otp(username)
      refute try_to_authenticate('wrong_username', 'wrong_password')
      refute try_to_authenticate(username, 'wrong_password')
      refute try_to_authenticate(username, 'wrong_password')
      refute try_to_authenticate('wrong_username', otp)
      assert try_to_authenticate(username, otp)
    end

    it 'authenticates correctly' do
      SecureRandom.stubs(:hex).returns(password)
      TestOtpManager.generate_otp(username)

      assert TestOtpManager.authenticate(base64)
    end

    it 'OTPs can be used only once' do
      SecureRandom.stubs(:hex).returns(password)
      TestOtpManager.generate_otp(username)

      assert TestOtpManager.authenticate(base64)
      refute TestOtpManager.authenticate(base64)
    end

    it 'creates token from username and password correctly' do
      _(TestOtpManager.tokenize(username, password)).must_equal base64
    end

    it 'overwrites old OTP when generating a new one for the same username' do
      old = TestOtpManager.generate_otp(username)
      new = TestOtpManager.generate_otp(username)
      refute try_to_authenticate(username, old)
      assert try_to_authenticate(username, new)
    end
  end
end
