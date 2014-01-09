require 'test/unit'
require 'pathname'
require Pathname(__FILE__).realpath.dirname.join('../testmock/miomock')
require 'miopon/api'

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

    # check nil[key], nil[index] and Array#[key]
    assert_nothing_raised(NoMethodError, TypeError,
                          'api coupon_info body type' ) do
      rtn[:body]['returnCode']
    end
    assert_equal('OK', rtn[:body]['returnCode'], 'api coupon_info returnCode')

    assert_nothing_raised(NoMethodError, TypeError,
                          'api coupon_info couponInfo type' ) do
      rtn[:body]['couponInfo'][0]['hddServiceCode']
    end

    assert_nothing_raised(NoMethodError, TypeError,
                          'api coupon_info hdoInfo type' ) do
      rtn[:body]['couponInfo'][0]['hdoInfo'][0]['hdoServiceCode']
      rtn[:body]['couponInfo'][0]['hdoInfo'][0]['number']
      rtn[:body]['couponInfo'][0]['hdoInfo'][0]['iccid']
      rtn[:body]['couponInfo'][0]['hdoInfo'][0]['regulation']
      rtn[:body]['couponInfo'][0]['hdoInfo'][0]['sms']
      rtn[:body]['couponInfo'][0]['hdoInfo'][0]['couponUse']
      rtn[:body]['couponInfo'][0]['hdoInfo'][0]['coupon'][0]['volume']
      rtn[:body]['couponInfo'][0]['hdoInfo'][0]['coupon'][0]['expire']
      rtn[:body]['couponInfo'][0]['hdoInfo'][0]['coupon'][0]['type']
    end

    assert_nothing_raised(NoMethodError, TypeError,
                          'api coupon_info coupon type' ) do
      rtn[:body]['couponInfo'][0]['coupon'][0]['volume']
      rtn[:body]['couponInfo'][0]['coupon'][0]['expire']
      rtn[:body]['couponInfo'][0]['coupon'][0]['type']
    end
  end

  def test_packet_log
    rtn = with_miomock(@dev_id, @access_token) do
      @api.packet_log
    end

    assert_equal('200', rtn[:status], 'api packet_log code')

    # check nil[key], nil[index] and Array#[key]
    assert_nothing_raised(NoMethodError, TypeError,
                          'api packet_log body type' ) do
      rtn[:body]['returnCode']
    end
    assert_equal('OK', rtn[:body]['returnCode'], 'api packet_log returnCode')

    assert_nothing_raised(NoMethodError, TypeError,
                          'api packet_log packetLogInfo type' ) do
      rtn[:body]['packetLogInfo'][0]['hddServiceCode']
    end

    assert_nothing_raised(NoMethodError, TypeError,
                          'api packet_log hdoInfo type' ) do
      rtn[:body]['packetLogInfo'][0]['hdoInfo'][0]['hddServiceCode']
      rtn[:body]['packetLogInfo'][0]['hdoInfo'][0]['packetLog'][0]['data']
      rtn[:body]['packetLogInfo'][0]['hdoInfo'][0]['packetLog'][0]['withCoupon']
      rtn[:body]['packetLogInfo'][0]['hdoInfo'][0]['packetLog'][0]['withoutCoupon']
    end
  end

  def test_switch
    rtn = with_miomock(@dev_id, @access_token) do
      @api.switch([['c1', true], ['c2', false]])
    end

    assert_equal('200', rtn[:status], 'api switch code')
    assert_nothing_raised(NoMethodError, TypeError,
                          'api switch body type' ) do
      rtn[:body]['returnCode']
    end
    assert_equal('OK', rtn[:body]['returnCode'], 'api switch returnCode')
  end
end
