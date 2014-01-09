require 'test/unit'
require 'minitest/mock'
require 'uri'
require 'json'
require 'miopon/api/auth'

class TestAuth < Test::Unit::TestCase
  def setup
    @param = { dev_id: 'mydevid', redirect_uri: 'myredirecturi',
      state: 'mystate' }
    @auth = Miopon::API::Auth.new(@param)
  end

  def test_gen_url
    uri = URI.parse(@auth.gen_url(@param))

    assert_equal('https', uri.scheme, 'auth gen_uri scheme')
    assert_equal('api.iijmio.jp', uri.host, 'auth gen_uri host')
    assert_equal('/mobile/d/v1/authorization/', uri.path, 'auth gen_uri path')

    query_h = uri.query.split(/&/).reduce({}) do |r, x|
      k, v = x.split(/=/, 2)
      r[k] = v
      r
    end
    assert_equal({ 'response_type' => 'token',
                   'client_id' => @param[:dev_id],
                   'redirect_uri' => @param[:redirect_uri],
                   'state' => @param[:state] },
                 query_h, 'auth gen_uri query' )
  end

  def test_auth
    access_token = 'myaccesstoken'
    expires_in = '500'

    success = Object.new
    def success.success?; true end
    Open3.stub(:capture3, [ JSON.generate({ 'access_token' => access_token,
                                            'expires_in' => expires_in,
                                            'state' => @param[:state],
                                            'token_type' => 'Bearer' }),
                            '',
                            success ]) do
      assert_nothing_raised('auth without error') do
        @auth.by_phantomjs('someuser', 'somepass', @param)
      end
    end

    assert_equal(access_token, @auth.access_token, 'auth access_token')
    assert_equal(expires_in, @auth.expires_in, 'auth expire_in')
    assert_equal(@param[:state], @auth.state, 'auth state')
  end

  def test_auth_server_error
    not_success = Object.new
    def not_success.success?; false end
    Open3.stub(:capture3, ['[]', '', not_success ]) do
      assert_raise(Miopon::API::Auth::PhantomJSError, 'auth server_error') do
        @auth.by_phantomjs('someuser', 'somepass', @param)
      end
    end
  end

  def test_auth_tokentype_error
    success = Object.new
    def success.success?; true end

    Open3.stub(:capture3, ['{"token_type": "dummy"}', '', success]) do
      assert_raise(Miopon::API::Auth::ResponseError, 'auth tokentype_error') do
        @auth.by_phantomjs('someuser', 'somepass', @param)
      end
    end
  end

  def test_auth_state_error
    success = Object.new
    def success.success?; true end

    assert_raise(Miopon::API::Auth::ResponseError, 'auth state_error') do
      Open3.stub(:capture3, [ '{"token_type": "Bearer", "state": "dummy"}',
                              '', success ]) do
        @auth.by_phantomjs('someuser', 'somepass', @param)
      end
    end
  end
end
