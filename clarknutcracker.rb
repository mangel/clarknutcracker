#clarknutcracker.rb
require 'sinatra/base'
require 'yaml'
require './core/proto.rb'

class Clarknutcracker < Sinatra::Base
	include Proto
	@@settings=nil
	@@counter=0
	@@proto_handler=nil

	before do
		@@settings=YAML.load_file('./config.yml')
	end

	get '/counter' do
		@@counter=@@counter+1
		"value is #{@@counter}"
	end

	get '/' do
		status="NONE"
		request_validation_status = validate_request_and_get_parameters(env)

		unless request_validation_status.nil?
			status="Request with valid headers"
			status=status+", command #{request_validation_status[:command]}"

			case request_validation_status[:command]
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
		status
	end
end
