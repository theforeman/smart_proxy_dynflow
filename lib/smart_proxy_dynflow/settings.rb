# frozen_string_literal: true

# require 'ostruct'

module Proxy::Dynflow
  class Settings
    def self.instance
      Proxy::Dynflow::Plugin.settings
    end
  end
end
