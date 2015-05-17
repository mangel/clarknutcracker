#clarknutcracker.rb
require 'sinatra/base'
require 'sinatra/json'
require 'yaml'
require 'securerandom'
require './core/proto.rb'

class Clarknutcracker < Sinatra::Base
	include Proto
	@@settings=nil
	@@counter=0
	@@proto_handler=nil

	@@db = Hash.new

	@request_date
	@request_uuid

	@rsp

	before do
		@request_date  = Time.now.utc
		@request_uuid  = SecureRandom.hex(128)
		
		@rsp = {
			:x_request_control_data => {
				:x_utc_request_date  => @request_date.strftime("%F %T.%L"),
				:x_utc_response_date => nil,
				:x_request_uuid      => @request_uuid,
				:x_status_message    => nil
			}
		}

		@@settings = YAML.load_file('./config.yml')
	end

	get '/counter' do
		@@counter=@@counter+1
		"value is #{@@counter}"
	end

	post '/' do
		rsp = Hash.new

		status="NONE"
		authentication_status = authenticate_request(@@settings["access_list"], env)
		if authentication_status == :authorized
			request_validation_status = validate_request_and_get_parameters(env, request)
			unless request_validation_status.nil?
				case request_validation_status[:command]
					when :subscribe
					when :unsubscribe
					when :change
					when :delete
					when :publish
						eviction_date = @request_date + 2

						@rsp[:x_data_uuid]     = request_validation_status[:args][:x_data_uuid]
						@rsp[:x_revision_uuid] = request_validation_status[:args][:x_revision_uuid]
						@rsp[:x_eviction_date] = eviction_date.strftime("%F %T.%L")

						#ALLOCATION CODE GOES HERE
						if @@db[@rsp[:x_data_uuid]].nil?
							@@db[@rsp[:x_data_uuid]] = { 
								:data => request.body.read, 
								:revision => @rsp[:x_revision_uuid],
								:eviction => eviction_date
							}
							status = "ALLOCATED"
						else
							status = "INVLDDATAUUID"
						end
					when :read
						data_uuid = request_validation_status[:args][:x_data_uuid]
						#Check if the data exists
						unless @@db[data_uuid].nil?
							item = @@db[data_uuid]
							unless Time.now.utc < item[:eviction]
								status = "EVICTED"
								@@db.delete(data_uuid)
							else
								@rsp[:data] = item[:data]
							end
						end
						#Check eviction date
				end
			end
		else
			#Logg this issue
		end

		@rsp[:x_request_control_data][:x_utc_response_date] = Time.now.utc.strftime("%F %T.%L")
		@rsp[:x_request_control_data][:x_status_message]    = status

		json @rsp
	end

	get '/tests' do
		json :foo => 'bar'

	end
end
