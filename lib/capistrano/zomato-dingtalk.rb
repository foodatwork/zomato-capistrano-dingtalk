require 'rest-client'
require_relative "zomato-dingtalk/version"
require_relative "zomato-dingtalk/messaging/base"
require_relative "zomato-dingtalk/messaging/text"
require_relative "zomato-dingtalk/messaging/markdown"
require 'forwardable'

load File.expand_path("../tasks/zomato_dingtalk.rake", __FILE__)

module Capistrano
  class ZomatoDingtalk
    extend Forwardable
    def_delegators :env, :fetch, :run_locally

    attr_reader :message
    def initialize(env)
      @env = env
      @config = fetch(:zomato_dingtalk_info, {})
      # TODO: supports more message categories
      klass = message_klass
      @message = klass.new @config
    end

    def run(action)
      local = self
      run_locally do
        info "begin to send action #{action} to Dingtalk"
        json = local.message.build_msg_json(action)
        local.send(:send_msg_to_ding_talk, json)
      end
    end

    def send_msg_to_ding_talk(json)
      url = @config[:url]
      RestClient.post(url, json, content_type: :json, accept: :json)
    end

    def message_klass
      category = @config[:category] || 'text'
      klass = Object
      case category
      when 'text'
        klass = ::Capistrano::ZomatoDingtalk::Messaging::Text
      when 'markdown'
        klass = ::Capistrano::ZomatoDingtalk::Messaging::Markdown
      end
      klass
    end
  end
end
