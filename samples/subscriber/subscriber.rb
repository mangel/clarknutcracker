require 'sinatra/base'
require 'sinatra/json'
require 'securerandom'
require './proto'

class Subscriber < Sinatra::Base
	@@db = Array.new
	@@q= Queue.new
	get '/load' do
		name = "DATA"
		url = "http://127.0.0.1:9292/"
		header = { 'x-command' => 'subscribe', 'x-auth-key' => 'aaa', 'x-data-uuid' => name, 'x-callback-url' => 'http://127.0.0.1:9296/changes' }

		res = Proto::send_post(url, nil, header)

		r = res.body
	end

	post '/changes' do
		unless env['HTTP_X_COMMAND'].nil?
			case env['HTTP_X_COMMAND']
				when 'change'
					@@q.enq({ :time => Time.now.utc.to_s, :op => :change })
					@@db.push({ :time => Time.now.utc, :op => :change, :data => request.body.read })
				when 'delete'
					@@db.push({ :time => Time.now.utc, :op => :delete })
			end
		end
		"OK"
	end

	post '/echo' do
		request.body.read
	end

	get '/push' do
		@@q.enq({:time => Time.now.utc.to_s, :op => 'NONE'})
		"OK"
	end
	get '/pull' do
		r = "OK"
		if @@q.length > 0
			r = @@q.deq
		else
			r = "NO CHANGES"
		end

		r.to_s
	end

	get '/data' do
		json @@db
	end

	get '/' do
		erb :index
	end
end
