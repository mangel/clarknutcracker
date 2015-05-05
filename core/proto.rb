module Proto

	class ProtoHandler
									@request=nil
									@config=nil
									@data_service
		def initialize(headers, data, config, data_service)
			@request = { :headers => headers, :data => data, :config => config }
			@data_service = data_service
		end

	end

	def validate_request_and_get_parameters(headers)
		result=nil
		command=nil
		unless headers.nil?
			unless headers['HTTP_X_COMMAND'].nil?
				case headers['HTTP_X_COMMAND'].downcase
					when 'publish'
						command = :publish
					when 'subscribe'
						command = :subscribe
					when 'unsubscribe'
						command = :unsubscribe
					when 'change'
						command = :change
					when 'delete'
						command = :delete
				end
				unless command.nil? 
								unless headers['HTTP_X_AUTH_KEY'].nil?
									result={:command => command, :auth_key => headers['HTTP_X_AUTH_KEY']}
								end
				end
			end
		end
		result
	end

	def validate_publish_request(headers)
		result=:valid
	end

	def validate_subscribe_request(headers)
		result=nil
		unless headers.nil?
		end
		result
	end

	def validate_change_request(headers)
	end

	def validate_delete_request(headers)
	end

	def validate_unsubscribe_request(headers)
	end
end
