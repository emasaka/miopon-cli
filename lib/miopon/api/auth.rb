require 'pathname'
require 'cgi'
require 'open3'
require 'json'

class Miopon
  class API
    class Auth
      def initialize(params)
        @params = params
      end

      JSFILE = Pathname(__FILE__).realpath.dirname.
        join('auth_by_phantomjs.js').to_s

      def by_phantomjs(user, pass, moreparams = {})
        allparams = @params.merge(moreparams)
        url = gen_url(allparams)
        # Don't give passwords as command argument!
        rtn, status = Open3.capture2({ 'MIOPON_USER' => user,
                                       'MIOPON_PASSWORD' => pass },
                                     'phantomjs', JSFILE, url );
        status.success? or raise # TODO: make some exception class
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
        # TODO: make some exception class
        data['token_type'] == 'Bearer' or raise
        data['state'] == params[:state] or raise

        @access_token = data['access_token']
        @state = data['state']
        @expires_in = data['expires_in']
      end

      attr_reader :access_token, :state, :expires_in
    end
  end
end
