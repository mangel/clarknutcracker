require 'dashing'
#require 'net/http'

configure do
  set :auth_token, 'YOUR_AUTH_TOKEN'

  helpers do
    def protected!
     # Put any authentication code you want in here.
     # This method is run before accessing any resource.
    end

#    def get_data(path)
#	    uri = URI("http://127.0.0.1:9292" + path)
#	    res = Net::HTTP.get(uri)
#	    return res
#   end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
