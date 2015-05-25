require 'sinatra/base'
require 'sinatra/json'
require 'securerandom'
require './proto'

class Subscriber < Sinatra::Base
	@@db = Array.new
	get '/load' do
		name = "DATA"
		url = "http://127.0.0.1:9292/"
		header = { 'x-command' => 'subscribe', 'x-auth-key' => 'aaa', 'x-data-uuid' => name, 'x-callback-url' => 'http://127.0.0.1:9296/changes' }

		res = Proto::send_post(url, nil, header)

		r = res.body
	end

	post '/changes' do
		begin
			unless env['HTTP_X_COMMAND'].nil?
				case env['HTTP_X_COMMAND']
					when 'change'
						@@db.push({ :time => Time.now.utc, :op => :change, :data => request.body.read })
					when 'delete'
						@@db.push({ :time => Time.now.utc, :op => :delete })
				end
			end
		rescue StandardError => bang
			@@db.push(bang)
		end
		"OK"
	end

	post '/echo' do
		request.body.read
	end

	get '/' do
		json @@db
	end
end
