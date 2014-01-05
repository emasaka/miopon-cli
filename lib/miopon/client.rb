require 'miopon/api'
require 'miopon/api/auth'

class Miopon
  class Client
    def initialize(dev_id, params = {})
      @dev_id = dev_id

      @access_token = params[:access_token]
      @expires_at = params[:expires_at]

      @username = params[:username]
      @password = params[:password]
      @redirect_uri = params[:redirect_uri]

      unless (@access_token && @expires_at) ||
          (@username && @password && @redirect_uri)
        raise                   # TODO: make some exception class
      end
    end

    attr_reader :access_token, :expires_at

    def coupon_info
      call_api { @api.coupon_info }['couponInfo'][0]
    end

    def packet_log
      call_api { @api.packet_log }['packetLogInfo'][0]
    end

    def switch(params)
      call_api { @api.switch(params) }
      self
    end

    def call_api
      check_auth

      res = yield
      if res[:status] != '200'
        # TODO: make some exception class
        raise "#{res[:status]}: #{res[:body]['returnCode']}"
      end
      res[:body]
    end

    def check_auth
      now = Time.now.to_i
      @access_token = @api = nil if @access_token && @expires_at < now # expire

      return if @api
      unless @access_token
        auth = Miopon::API::Auth.new(dev_id: @dev_id,
                                     redirect_uri: @redirect_uri )
        auth.by_phantomjs(@username, @password, state: now.to_s)
        @access_token = auth.access_token
        @expires_at = auth.expires_in.to_i + now
      end
      @api = Miopon::API.new(@dev_id, @access_token)
    end
  end
end
