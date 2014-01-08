require 'test/unit'
require 'pathname'
require 'open3'
require 'json'

JSFILE = Pathname(__FILE__).realpath.dirname.
  join('../../lib/miopon/api/auth_by_phantomjs.js').to_s

AUTHMOCK_URI = 'file://' +
  Pathname(__FILE__).realpath.dirname.join('../testmock/authmock.html').to_s

def phantomjs(user, pass, jsfile, uri)
  Open3.capture2({ 'MIOPON_USER' => user, 'MIOPON_PASSWORD' => pass },
                 'phantomjs', jsfile, uri );
end

class TestAuthByPhantomJS < Test::Unit::TestCase
  def test_login
    username = 'someuser'
    password = 'somepass'

    rtn, status = phantomjs(username, password, JSFILE, AUTHMOCK_URI)

    assert(status.success?, 'login')

    data = JSON.parse(rtn)
    assert_equal({ 'access_token' => 'user:' + username,
                   'state' => 'password:' + password,
                   'token_type' => 'Bearer',
                   'expires_in' => '500' },
                 data,
                 'login data' )
  end

  def test_timeout
    rtn, status = phantomjs('someuser', 'somepass', JSFILE,
                            AUTHMOCK_URI + '?pagemove=no' )

    assert(!status.success?, 'timeout')

    errorpng = 'miopon_auth_error.png'
    File.delete(errorpng) if File.exist?(errorpng)
  end
end
