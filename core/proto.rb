module Proto
	require 'securerandom'

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
						command = :subscribe
					when 'unsubscribe'
						command = :unsubscribe
					when 'change'
						command = :change
					when 'delete'
						command = :delete
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
		status=:unauthorized
		unless headers.nil?
			unless headers['HTTP_X_AUTH_KEY'].nil?
				key=headers['HTTP_X_AUTH_KEY']
				hosts.each do |h|
					if h["auth_key"].eql? key
						status=:authorized
						break
					end
				end
			end
		end
		status
	end
end
