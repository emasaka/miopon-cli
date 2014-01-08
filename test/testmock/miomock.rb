require 'minitest/mock'
require 'net/https'
require 'uri'
require 'json'

ResponseMock = Struct.new(:code, :body)

class NetHttpMioMock
  def initialize(host, port = 80)
    @host = host
    @port = port
  end

  attr_accessor :use_ssl, :dev_id, :access_token

  def start
    yield self
  end

  def get(path, hdr = {})
    _request(:get, path, nil, hdr)
  end

  def put(path, data, hdr = {})
    _request(:put, path, data, hdr)
  end

  # response sampie is taken from official API document
  INFO_DATA = <<'__EOID__'
{
  "returnCode"      : "OK",
  "couponInfo"     : [
      {
        "hddServiceCode": "hddXXXXXXXX",
        "hdoInfo"       : [
            {
                "hdoServiceCode": "hdoXXXXXXXX",
                "number"        : "080XXXXXXXX",
                "iccid"         : "DN00XXXXXXXXXX",
                "regulation"    : true,
                "sms"           : true,
                "couponUse"     : true,
                "coupon"        : [
                    { "volume": 100, "expire": null, "type": "sim" }
                ]
            }
        ],
       "coupon"          : [
           {"volume":100, "expire":"201312", "type":"bundle"},
           {"volume":200, "expire":"201401", "type":"bundle"},
           {"volume":0,   "expire":"201312", "type":"topup"},
           {"volume":400, "expire":"201401", "type":"topup"},
           {"volume":0,   "expire":"201402", "type":"topup"},
           {"volume":400, "expire":"201403", "type":"topup"}
       ]
     }
  ]
}
__EOID__

  LOG_PACKET_DATA = <<'__EOLPD__'
{
  "returnCode"      : "OK",
  "packetLogInfo"   : [
      {
        "hddServiceCode": "hddXXXXXXXX",
        "hdoInfo"       : [
            {
                "hdoServiceCode": "hdoXXXXXXXX",
                "packetLog"     : [
                    { "date": "20131101", "withCoupon": 50, "withoutCoupon": 50 },
                    { "date": "20131102", "withCoupon": 50, "withoutCoupon": 50 },
                    { "date": "20131103", "withCoupon": 50, "withoutCoupon": 50 },
                    { "date": "20131104", "withCoupon": 0, "withoutCoupon": 0 }
                ]
            }
        ]
     }
  ]
}
__EOLPD__

  def _request(meth, path, data, hdr)
    code = body = nil
    if ! hdr.has_key?('X-IIJmio-Authorization')
      code = '403'
      body = _codeonly('X-IIJmio-Authorization is not found')
    elsif ! hdr.has_key?('X-IIJmio-Developer')
      code = '403'
      body = _codeonly('X-IIJmio-Developer is not found')
    elsif hdr['X-IIJmio-Authorization'] != @access_token ||
        hdr['X-IIJmio-Developer'] != @dev_id
      puts "<<#{@access_token}>>"
      body = _codeonly('Your application is not registered')
    elsif meth == :get && path == '/mobile/d/v1/coupon/'
      code = '200'
      body = INFO_DATA
    elsif meth == :get && path == '/mobile/d/v1/log/packet/'
      code = '200'
      body = LOG_PACKET_DATA
    elsif meth == :put && path == '/mobile/d/v1/coupon/'
      d = JSON.parse(data)
      if (ci = d['couponInfo']) && ci.instance_of?(Array) &&
          (hi = ci[0]['hdoInfo']) && hi.instance_of?(Array) &&
          hi[0]['hdoServiceCode'].instance_of?(String) &&
          (hi[0]['couponUse'].instance_of?(TrueClass) ||
           hi[0]['couponUse'].instance_of?(FalseClass) )
        code = '200'
        body = _codeonly('OK')
      else
        code = '400'
        body = _codeonly('Your data structure or data type is invalid')
      end
    else
      code = '404'
      body = _codeonly('Not Found')
    end

    ResponseMock.new(code, body)
  end

  def _codeonly(message)
    JSON.generate({ "returnCode" => message })
  end
end

def with_miomock(dev_id, access_token)
  Net::HTTP.stub(:new, ->(*args) {
                   h = NetHttpMioMock.new(*args)
                   h.dev_id = dev_id
                   h.access_token = access_token
                   h
                 }) do
    yield
  end
end
