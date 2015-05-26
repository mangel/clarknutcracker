require 'net/http'
require 'json'

current_valuation = 0
current_karma = 0

SCHEDULER.every '5s' do
  #get rpc data
  uri = URI("http://127.0.0.1:9292/rpc")

  rpc_s = Net::HTTP.get(uri)

  #get valuation
  uri = URI("http://127.0.0.1:9292/valuation")

  valuation_json = JSON(Net::HTTP.get(uri))

  current_valuation = valuation_json['current_val']
  last_valuation = valuation_json['last_valuation']

  send_event('rpc', { value: rpc_s.to_i })
  send_event('valuation', { current: current_valuation, last: last_valuation })
  #send_event('karma', { current: current_karma, last: last_karma })
end
