require 'erb'
require 'json'
require 'miopon/client'

class MioponCLI
  CONFFILE = File.expand_path('~/.miopon-cli')

  def initialize
    # TODO: create new config if not exist
    @conf = load_config
    @conf[:expires_at] = @conf[:expires_at].to_i if @conf[:expires_at]
    @client = Miopon::Client.new(@conf[:dev_id], @conf)
  end

  INFO_FMT = <<'__INFO_FMT__'
hddServiceCode: <%= info['hddServiceCode'] %>
hdoInfo:
<% info['hdoInfo'].each_with_index do |hdo, i| -%>
  (<%= i + 1 %>):
    hdoServiceCode: <%= hdo['hdoServiceCode'] %>
    number: <%= hdo['number'] %>
    couponUse: <%= hdo['couponUse'] %>
<%- end -%>
coupon:
<% info['coupon'].each_with_index do|coupon, i| -%>
  <%- next if coupon['volume'].zero? -%>
  - expire: <%= coupon['expire'].sub(/(\d{4})(\d{2})(\d{2})/, '\1.\2.\3') %>, volume: <%= coupon['volume'] %>, type: <%= coupon['type'] %>
<%- end -%>
__INFO_FMT__

  LOG_FMT = <<'__LOG_FMT__'
hddServiceCode: <%= info['hddServiceCode'] %>
hdoInfo:
<% info['hdoInfo'].each_with_index do |hdo, i| -%>
  (<%= i + 1 %>) hdoServiceCode: <%= hdo['hdoServiceCode'] %>
  <%- hdo['packetLog'].each do |x| -%>
    <%- next if x['withCoupon'].zero? && x['withoutCoupon'].zero? -%>
    - date: <%= x['date'].sub(/(\d{4})(\d{2})(\d{2})/, '\1.\2.\3') -%>, withCoupon: <%= '%4d' % x['withCoupon'] %>, withoutCoupon: <%= '%4d' %  x['withoutCoupon'] %>
  <%- end -%>
<%- end -%>
__LOG_FMT__

  def info_cmd(format)
    rtn = @client.coupon_info
    maybe_save_config

    case format
    when 'text'
      info = rtn['couponInfo'][0]
      print ERB.new(INFO_FMT, nil, '-').result(binding)
    when 'json'
      print JSON.generate(rtn)
    end
  end

  def log_cmd(format)
    rtn = @client.packet_log
    maybe_save_config

    case format
    when 'text'
      info = rtn['packetLogInfo'][0]
      print ERB.new(LOG_FMT, nil, '-').result(binding)
    when 'json'
      print JSON.generate(rtn)
    end
  end

  def switch_cmd(on)
    info = @client.coupon_info['couponInfo'][0]
    hdo = info['hdoInfo'][0]
    if hdo['couponUse'] != on
      @client.switch([[hdo['hdoServiceCode'], on]])
      maybe_save_config
    end
  end

  def load_config
    conf = {}
    open(CONFFILE, 'r') do |i|
      i.each_line do |line|
        k, v = line.chomp.split(/\s*:\s*/, 2)
        conf[k.to_sym] = v
      end
    end
    conf
  end

  def maybe_save_config
    if @client.access_token != @conf[:access_token]
      @conf[:access_token] = @client.access_token
      @conf[:expires_at] = @client.expires_at
      save_config(@conf)
    end
  end

  def save_config(conf)
    open(CONFFILE, 'w', 0600) do |o|
      conf.each {|k, v| o.puts "#{k}: #{v}" }
    end
  end
end
