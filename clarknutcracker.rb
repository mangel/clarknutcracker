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

	@@stats = { 
		:rpc => 0, 
		:ops => {
			:read => 0, :publishes => 0, :subscribes => 0, :unsubscribes => 0, :changes => 0}, 
		:mem => { :max => 500, :allocated => 0 },
		:timing => {:last_val => 0, :current_val => 0}
       	}

	@request_date
	@request_uuid

	@rsp

	@@statsSemaphore = Mutex.new

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
		Thread.new {
			@@statsSemaphore.synchronize {
				@@stats[:rpc] += 1
			}
		}
		rsp = Hash.new

		status="NONE"
		authentication_status = authenticate_request(@@settings["access_list"], env)
		if authentication_status[:auth_status] == :authorized
			request_validation_status = validate_request_and_get_parameters(env, request)
			unless request_validation_status.nil?
				case request_validation_status[:command]
					when :subscribe
						Thread.new{
							@@statsSemaphore.synchronize {
								@@stats[:ops][:subscribes] += 1
							}
						}
						data_uuid    = request_validation_status[:args][:x_data_uuid]
						hostname     = authentication_status[:hostname]
						callback_url = request_validation_status[:args][:x_callback_url]
						#DATA LOOKUP
						unless @@db[data_uuid].nil?
							item = @@db[data_uuid]
							if item[:subscribers][hostname].nil?
								item[:subscribers][hostname] = { :url => callback_url}
							else
								item[:subscribers][hostname][:url] = callback_url
							end

							status = "SUBSCRIBED"

							@rsp[:data] = item[:data]
						else
							status = "INVLDDATAUUID"
						end
					when :unsubscribe
						data_uuid = request_validation_status[:args][:x_data_uuid]
						hostname  = authentication_status[:hostname]
						#DATA LOOKUP
						unless @@db[data_uuid].nil?
							status = "UNSUBSCRIBED" unless @@db[data_uuid][:subscribers].delete(hostname).nil?
						else
							status = "INVLDDATAUUID"
						end
					when :change
						@@statsSemaphore.synchronize {
							@@stats[:ops][:changes] += 1
						}
						data_uuid     = request_validation_status[:args][:x_data_uuid]
						revision_uuid = request_validation_status[:args][:x_revision_uuid]
						new_revision_uuid = SecureRandom.hex(80)



						new_revision_uuid = 'a'



						#DATA LOOKUP
						unless @@db[data_uuid].nil?
							if @@db[data_uuid][:revision].eql? revision_uuid
								@@db[data_uuid][:data] = request.body.read
								@@db[data_uuid][:x_revision_uuid] = new_revision_uuid
								#NOTIFY TO OTHER HOSTS THE CHANGE OF THIS ITEM
								Thread.new{
									push_notifications({'x-command' => 'change'}, @@db[data_uuid][:subscribers], @@db[data_uuid][:data])
								}
								@rsp[:x_revision_uuid] = new_revision_uuid

								status = "CHANGED"
							end
						else
							status = "INVLDDATAUUID"
						end
					when :delete
						data_uuid     = request_validation_status[:args][:x_data_uuid]
						revision_uuid = request_validation_status[:args][:x_revision_uuid]
						#DATA LOOKUP
						unless @@db[data_uuid].nil?
							if @@db[data_uuid][:revision].eql? revision_uuid
								#NOTIFY TO OTHER HOSTS THE DELETION OF THIS ITEM
								Thread.new {
									@@db.delete(data_uuid)
									push_notifications({'x-command' => 'delete'}, @@db[data_uuid][:subscribers], nil)
								}
								status = "DELETED"
							end
						else
							status = "INVLDDATAUUID"
						end
					when :publish
						@@statsSemaphore.synchronize {
							@@stats[:ops][:publishes] += 1
						}
						eviction_date = @request_date + 3600
						data_uuid     = request_validation_status[:args][:x_data_uuid]
						revision_uuid = request_validation_status[:args][:x_revision_uuid]
						#ALLOCATION CODE GOES HERE
						if @@db[data_uuid].nil?
							@@db[data_uuid] = { 
								:data        => request.body.read, 
								:revision    => revision_uuid,
								:eviction    => eviction_date,
								:subscribers => Hash.new
							}

							@rsp[:x_data_uuid]     = data_uuid
							@rsp[:x_revision_uuid] = revision_uuid
							@rsp[:x_eviction_date] = eviction_date.strftime("%F %T.%L")

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
				end
			end
		else
			#Logg this issue
		end

		Thread.new{
			@@statsSemaphore.synchronize {
				@@stats[:timing][:last_val] = @@stats[:timing][:current_val]
				@@stats[:timing][:current_val] =  Time.now.utc - @request_date;
			}
		}

		@rsp[:x_request_control_data][:x_utc_response_date] = Time.now.utc.strftime("%F %T.%L")
		@rsp[:x_request_control_data][:x_status_message]    = status

		json @rsp
	end

	get '/tests' do
		env['HTTP_X_CALLBACK_URL']
	end

	get '/rpc' do
		r = 0
		@@statsSemaphore.synchronize {
			r = @@stats[:rpc]
			@@stats[:rpc] = 0
		}
		r.to_s
	end

	get '/valuation' do
		json @@stats[:timing]
	end

	get '/operations' do
		r = {:reads => 0, :publishes => 0, :subscribes => 0, :unsubscribes => 0}
		@@statsSemaphore.synchronize {
			r = @@stats[:ops]
			#@@stats[:ops][:reads] = 0
			#@@stats[:ops][:publishes] = 0
			#@@stats[:subscribes] = 0
			#@@stats[:unsubscribes] = 0
		}
		json r
	end
end
