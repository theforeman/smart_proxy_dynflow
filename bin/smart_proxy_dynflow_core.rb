#!/usr/bin/env ruby
require 'dynflow'
require 'rack'
require 'smart_proxy_dynflow_core/launcher'
require 'yaml'

SmartProxyDynflowCore::Launcher.launch!
