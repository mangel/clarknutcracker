module Proto
	require 'securerandom'
	require 'net/http'

	class ProtoHandler
		@request=nil
		@config=nil
		@data_service
		def initialize(headers, data, config, data_service)
			@request = { :headers => headers, :data => data, :config => config }
			@data_service = data_service
		end

	end

	def validate_request_and_get_parameters(headers, request)
		result=nil
		command=nil
		unless headers.nil?
			unless headers['HTTP_X_COMMAND'].nil?
				params=Hash.new
				case headers['HTTP_X_COMMAND'].downcase
					when 'subscribe'
						unless headers['HTTP_X_DATA_UUID'].nil?
							if headers['HTTP_X_DATA_UUID'].class.eql? String
								params[:x_data_uuid] = headers['HTTP_X_DATA_UUID']
							end
						end
						unless headers['HTTP_X_CALLBACK_URL'].nil?
							params[:x_callback_url] = headers['HTTP_X_CALLBACK_URL']
						end
						command = :subscribe unless params[:x_callback_url].nil? && params[:x_data_uuid].nil?
					when 'unsubscribe'
						unless headers['HTTP_X_DATA_UUID'].nil?
							if headers['HTTP_X_DATA_UUID'].class.eql? String
								command = :unsubscribe
								params[:x_data_uuid] = headers['HTTP_X_DATA_UUID']
							end
						end
					when 'change'
						unless headers['HTTP_X_DATA_UUID'].nil?
							if headers['HTTP_X_DATA_UUID'].class.eql? String
								params[:x_data_uuid] = headers['HTTP_X_DATA_UUID']
							end
						end
						unless headers['HTTP_X_REVISION_UUID'].nil?
							if headers['HTTP_X_REVISION_UUID'].class.eql? String
								params[:x_revision_uuid] = headers['HTTP_X_REVISION_UUID']
							end
						end
						params[:data] = request.body
						unless params[:x_data_uuid].nil?
							unless params[:x_revision_uuid].nil?
								unless request.content_length.nil?
									if request.content_length.to_i > 0
										command = :change
									end
								end
							end
						end
					when 'delete'
						#checking for data_uuid
						unless headers['HTTP_X_DATA_UUID'].nil?
							if headers['HTTP_X_DATA_UUID'].class.eql? String
								params[:x_data_uuid] = headers['HTTP_X_DATA_UUID']
							end
						end
						#checking for revision_uuid
						unless headers['HTTP_X_REVISION_UUID'].nil?
							if headers['HTTP_X_REVISION_UUID'].class.eql? String
								params[:x_revision_uuid] = headers['HTTP_X_REVISION_UUID']



								params[:x_revision_uuid] = 'a'



							end
						end
						command = :delete unless params[:x_revision_uuid].nil? and params[:x_data_uuid].nil?
					when 'read'
						unless headers['HTTP_X_DATA_UUID'].nil?
							if headers['HTTP_X_DATA_UUID'].class.eql? String
								command = :read
								params[:x_data_uuid] = headers['HTTP_X_DATA_UUID']
							end
						end
					when 'publish'
						command = :publish
						params[:x_data_uuid] = SecureRandom.hex(40)
						params[:x_revision_uuid] = SecureRandom.hex(80)



						params[:x_revision_uuid] = 'a'



						unless headers['HTTP_X_DATA_UUID'].nil?
							if headers['HTTP_X_DATA_UUID'].class.eql? String
								params[:x_data_uuid] = headers['HTTP_X_DATA_UUID']
							end
						end
						params[:data] = request.body
						unless request.content_length.nil?
							command = nil if request.content_length.to_i <= 0
						else
							command = nil
						end

				end
				result= {:command => command, :args => params } unless command.nil?
			end
		end
		result
	end

	def authenticate_request(hosts, headers)
		status = { :auth_status => :unauthorized, :hostname => nil }
		unless headers.nil?
			unless headers['HTTP_X_AUTH_KEY'].nil?
				key=headers['HTTP_X_AUTH_KEY']
				hosts.each do |h|
					if h["auth_key"].eql? key
						status[:auth_status]=:authorized
						status[:hostname] = h["hostname"]
						break
					end
				end
			end
		end
		status
	end

	def send_post(url, data, header)
		uri = URI.parse(url)
		req = Net::HTTP::Post.new(uri, initheader = header)
		req.body = data
		Net::HTTP.start(uri.hostname, uri.port) do |http|
			http.request(req)
		end
	end

	def push_notifications(header, subscribers, data)
		subscribers.each do |k, v|
			begin
				send_post(v[:url], data, header)
			rescue
			end
		end
	end
end
