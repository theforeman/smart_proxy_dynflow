# require 'ostruct'

module SmartProxyDynflowCore
  class Settings
    def self.instance
      Proxy::Dynflow::Plugin.settings
    end
  end
end
