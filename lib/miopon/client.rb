require 'miopon/api'
require 'miopon/api/auth'

class Miopon
  class Client

    class ParameterError < StandardError; end
    class HttpError < StandardError; end
    %w(403 413 429 500 503).each do |code|
      const_set("C#{code}Error", Class.new(StandardError))
    end

    def initialize(dev_id, params = {})
      unless dev_id && String === dev_id
        raise ParameterError, "dev_id: #{dev_id.inspect}"
      end
      @dev_id = dev_id

      @access_token = params[:access_token]
      @expires_at = params[:expires_at]

      @username = params[:username]
      @password = params[:password]
      @redirect_uri = params[:redirect_uri]

      unless (@access_token && @expires_at) ||
          (@username && @password && @redirect_uri)
        raise ParameterError, 'need access_token+expires_at or username+password+redirect_uri'
      end
    end

    attr_reader :access_token, :expires_at

    def coupon_info
      call_api { @api.coupon_info }
    end

    def packet_log
      call_api { @api.packet_log }
    end

    def switch(params)
      call_api { @api.switch(params) }
      self
    end

    def call_api
      check_auth

      res = yield
      if res[:status] != '200'
        begin
          error_class = self.class.const_get("C#{res[:status]}Error")
          message = res[:body]['returnCode']
        rescue NameError
          error_class = HttpError
          message = res[:status]
        end
        raise error_class, message
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
        if @username && @password
          auth.by_phantomjs(@username, @password, state: now.to_s)
        else
          auth.by_external(state: now.to_s)
        end
        @access_token = auth.access_token
        @expires_at = auth.expires_in.to_i + now
      end
      @api = Miopon::API.new(@dev_id, @access_token)
    end
  end
end
