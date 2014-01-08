require 'test/unit'
require 'json'
require 'pathname'
require Pathname(__FILE__).realpath.dirname.join('../testmock/miomock')
require 'miopon/api'

def boolean?(object)
  object.instance_of?(TrueClass) || object.instance_of?(FalseClass)
end

class TestAPI < Test::Unit::TestCase
  def setup
    @dev_id = 'someid'
    @access_token = 'sometoken'
    @api = Miopon::API.new(@dev_id, @access_token)
  end

  def test_coupon_info
    rtn = with_miomock(@dev_id, @access_token) do
      @api.coupon_info
    end
    assert_equal('200', rtn[:status], 'api coupon_info code')
    assert_instance_of(Hash, rtn[:body], 'api coupon_info body type')
    assert_equal('OK', rtn[:body]['returnCode'], 'api coupon_info returnCode')
    ci = rtn[:body]['couponInfo']
    assert_instance_of(Array, ci, 'api coupon_info couponInfo type')
    assert_instance_of(Hash, ci[0], 'api coupon_info couponInfo[0] type')
    assert_instance_of(String, ci[0]['hddServiceCode'],
                       'api coupon_info hddServiceCode type' )

    hi = ci[0]['hdoInfo']
    assert_instance_of(Array, hi, 'api coupon_info hdoInfo type')
    assert_instance_of(Hash, hi[0], 'api coupon_info hdoInfo[0] type')
    assert_instance_of(String, hi[0]['hdoServiceCode'],
                       'api coupon_info hdoServiceCode type' )
    assert_instance_of(String, hi[0]['number'], 'api coupon_info number type')
    assert_instance_of(String, hi[0]['iccid'], 'api coupon_info iccid type')
    assert(boolean?(hi[0]['regulation']), 'api coupon_info regulation type')
    assert(boolean?(hi[0]['sms']), 'api coupon_info sms type')
    assert(boolean?(hi[0]['couponUse']), 'api coupon_info sms type')
    assert_instance_of(Array, hi[0]['coupon'],
                       'api coupon_info hdoInfo[0] coupon type' )

    coupon = ci[0]['coupon']
    assert_instance_of(Array, coupon, 'api coupon_info coupon type')
    assert_instance_of(Hash, coupon[0], 'api coupon_info coupon[0] type')
    assert(['volume', 'expire', 'type'].map {|k| coupon[0].has_key?(k) }.all?,
           'api coupon_info coupon item type' )
  end

  def test_packet_log
    rtn = with_miomock(@dev_id, @access_token) do
      @api.packet_log
    end

    assert_equal('200', rtn[:status], 'api packet_log code')
    assert_instance_of(Hash, rtn[:body], 'api packet_log body type')
    assert_equal('OK', rtn[:body]['returnCode'], 'api packet_log returnCode')
    pi = rtn[:body]['packetLogInfo']
    assert_instance_of(Array, pi, 'api packet_log packetLogInfo type')
    pi0 = pi[0]
    assert_instance_of(Hash, pi0, 'api packet_log packetLogInfo[0] type')
    assert_instance_of(String, pi0['hddServiceCode'],
                       'api packet_log hddServiceCode type' )
    hi = pi0['hdoInfo']
    assert_instance_of(Array, hi, 'api packet_log hdoInfo type')
    assert_instance_of(Hash, hi[0], 'api packet_log hdoInfo[0] type')
    assert_instance_of(String, hi[0]['hdoServiceCode'],
                       'api packet_log hdoServiceCode type' )
    pl = hi[0]['packetLog']
    assert_instance_of(Array, pl, 'api packet_log packetLog type')
    assert_instance_of(Hash, pl[0], 'api packet_log packetLog[0] type')
    assert(['date', 'withCoupon', 'withoutCoupon'].map {|k|
             pl[0].has_key?(k) }.all?,
           'api packet_log pcketLog[0] type' )
  end

  def test_switch
    rtn = with_miomock(@dev_id, @access_token) do
      @api.switch([['c1', true], ['c2', false]])
    end

    assert_equal('200', rtn[:status], 'api switch code')
    assert_instance_of(Hash, rtn[:body], 'api switch body type')
    assert_equal('OK', rtn[:body]['returnCode'], 'api switch returnCode')
  end
end
