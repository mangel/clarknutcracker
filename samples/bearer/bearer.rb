require 'sinatra/base'
require 'securerandom'
require './proto'

class Bearer < Sinatra::Base
	get '/shoot' do
		data = SecureRandom.base64(1024*8)
		name = "DATA"
		url = "http://127.0.0.1:9292/"
		header = { 'x-command' => 'publish', 'x-auth-key' => 'aaa', 'x-data-uuid' => name }

		res = Proto::send_post(url, data, header)

		r = res.body
	end

	get '/change' do
		data = SecureRandom.base64(1024*8)
		name = "DATA"
		url  = "http://127.0.0.1:9292"
		header = { 'x-command' => 'change', 'x-auth-key' => 'aaa', 'x-data-uuid' => name, 'x-revision-uuid' => 'a' }
		res = Proto::send_post(url, data, header)

		r = res.body
	end

	get '/' do
		erb :index
	end
end
