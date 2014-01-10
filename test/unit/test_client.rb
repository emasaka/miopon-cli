require 'test/unit'
require 'minitest/mock'
require 'pathname'
require Pathname(__FILE__).realpath.dirname.join('../testmock/miomock')
require 'miopon/client'

class TestClient < Test::Unit::TestCase
  def test_parameter_error
    assert_raise(Miopon::Client::ParameterError,
                 'client test_parameter_error dev_id' ) do
      Miopon::Client.new(nil)
    end
    assert_raise(Miopon::Client::ParameterError,
                 'client test_parameter_error no expires_at' ) do
      Miopon::Client.new('someid', access_token: 'sometoken')
    end
    assert_raise(Miopon::Client::ParameterError,
                 'client test_parameter_error no password' ) do
      Miopon::Client.new('someid', username: 'someuser')
    end
    assert_nothing_raised('client test_parameter_error with username' ) do
      Miopon::Client.new('someid', username: 'someuser', password: 'somepass',
                         redirect_uri: '/path/to/example' )
    end
    assert_nothing_raised('client test_parameter_error with token' ) do
      Miopon::Client.new('someid', access_token: 'sometoken', expires_at: 1)
    end
  end

  def test_check_auth
    Miopon::API::Auth.stub(:new, ->(*_){ throw :auth_called }) do
      assert_throws(:auth_called, 'client check_auth') do
        Miopon::Client.new('someid', username: 'someuser', password: 'somepass',
                           redirect_uri: '/path/to/example' ).check_auth
      end
      assert_nothing_thrown('client check_auth with token') do
        Miopon::Client.new('someid', access_token: 'xxx',
                           expires_at: Time.now.to_i + 100 ).check_auth
      end
      assert_throws(:auth_called, 'client check_auth with old token') do
        Miopon::Client.new('someid', access_token: 'xxx',
                           expires_at: Time.now.to_i - 100 ).check_auth
      end
    end
  end

  def test_call_api
    client = Miopon::Client.new('someid', access_token: 'xxx',
                                expires_at: Time.now.to_i + 1000 )
    resbody = '{ "returnCode": "OK" }'

    rtn = nil
    assert_nothing_raised('client call_api respods 200') do
      rtn = client.call_api { { status: '200', body: resbody } }
    end
    assert_equal(resbody, rtn, 'client call_api respods OK')

    assert_raise(Miopon::Client::C403Error, 'client call_api respods 403') do
      client.call_api { { status: '403', body: resbody } }
    end
  end
end
