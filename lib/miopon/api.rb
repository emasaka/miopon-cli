require 'net/https'
require 'json'

class MioponAPI
  def initialize(dev_id, access_token)
    @dev_id = dev_id
    @access_token = access_token
  end

  def coupon_info
    get '/mobile/d/v1/coupon/'
  end

  def switch(params)
    info = params.map {|code, on| { hdoServiceCode: code, couponUse: !!on } }
    put('/mobile/d/v1/coupon/', { couponInfo: [{ hdoInfo: info }] })
  end

  def packet_log
    get '/mobile/d/v1/log/packet/'
  end

  def get(path)
    request do |h|
      h.get(path,
            { 'X-IIJmio-Developer' => @dev_id,
              'X-IIJmio-Authorization' => @access_token } )
    end
  end

  def put(path, data)
    request do |h|
      h.put(path,
            JSON.generate(data),
            { 'X-IIJmio-Developer' => @dev_id,
              'X-IIJmio-Authorization' => @access_token,
              'Content-Type' => 'application/json' } )
    end
  end

  def request
    https = Net::HTTP.new('api.iijmio.jp', 443)
    https.use_ssl = true
    rtn = https.start {|h| yield h }
    { status: rtn.code, body: JSON.parse(rtn.body) }
  end
end
