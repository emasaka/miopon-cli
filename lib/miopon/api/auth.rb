require 'pathname'
require 'cgi'
require 'open3'
require 'json'

class Miopon
  class API
    class Auth

      class PhantomJSError < StandardError; end
      class ResponseError < StandardError; end

      def initialize(params)
        @params = params
      end

      JSFILE = Pathname(__FILE__).realpath.dirname.
        join('auth_by_phantomjs.js').to_s

      def by_phantomjs(user, pass, moreparams = {})
        allparams = @params.merge(moreparams)
        url = gen_url(allparams)
        # Don't give passwords as command argument!
        rtn, err, status = Open3.capture3({ 'MIOPON_USER' => user,
                                            'MIOPON_PASSWORD' => pass },
                                          'phantomjs', '--ssl-protocol=any',
                                          JSFILE, url )
        status.success? or raise PhantomJSError, err
        store_tokens(JSON.parse(rtn), allparams)
      end

      def gen_url(params)
        'https://api.iijmio.jp/mobile/d/v1/authorization/?' +
          'response_type=token' +
          "&client_id=#{params[:dev_id]}" +
          "&redirect_uri=#{CGI.escape(params[:redirect_uri])}" +
          "&state=#{CGI.escape(params[:state])}"
      end

      def store_tokens(data, params)
        if data['token_type'] != 'Bearer'
          raise ResponseError, "token_type was #{data['token_type']}, instead of Bearer"
        end
        if data['state'] != params[:state]
          raise ResponseError, "state was #{data['state']}, instead of #{params[:state]}"
        end

        @access_token = data['access_token']
        @state = data['state']
        @expires_in = data['expires_in']
      end

      attr_reader :access_token, :state, :expires_in
    end
  end
end
