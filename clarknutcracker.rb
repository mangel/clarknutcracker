#clarknutcracker.rb
require 'sinatra/base'
require 'yaml'
require './core/proto.rb'

class Clarknutcracker < Sinatra::Base
	include Proto
	@@settings=nil
	@@counter=0
	@@proto_handler=nil
	@@datastore=Hash.new
	@request_data
	before do
		@@settings=YAML.load_file('./config.yml')
		@request_data=request.body.read.to_s
	end

	get '/counter' do
		@@counter=@@counter+1
		"value is #{@@counter}"
	end

	post '/data' do
					"#{@request_data}\r\n"
	end

	post '/' do
		status="NONE"
		request_validation_status = validate_request_and_get_parameters(env)
		authenticated=false
		unless request.nil?
			unless request_validation_status.nil?
				@@settings['access_list'].each do |x|
					if x['auth_key'].eql? request_validation_status[:auth_key]
						authenticated=true
						break
					end
				end
				if authenticated
					status="Request with valid headers"
					status=status+", command #{request_validation_status[:command]}"
					status=status+", auth_key #{request_validation_status[:auth_key]}"
					case request_validation_status[:command]
						when :publish
						
						when :subscribe
							request_validation_status[:command_validation_status]=validate_subscribe_request(env)
						when :unsubscribe
							request_validation_status[:command_validation_status]=validate_unsubscribe_request(env)
						when :change
							request_validation_status[:command_validation_status]=validate_change_request(env)
						when :delete
							request_validation_status[:command_validation_status]=validate_delete_request(env)
					end
					unless request_validation_status[:command_validation_status].nil?
						case request_validation_status[:command]
							when :subscribe

							when :unsubscribe
							when :change
							when :delete
						end
					end
				end
			end
		end
		status=status+"\r\n"
	end
end
