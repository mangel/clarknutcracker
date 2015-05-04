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
					when 'subscribe'
						command = :subscribe
					when 'unsubscribe'
						command = :unsubscribe
					when 'change'
						command = :change
					when 'delete'
						command = :delete
				end
				result= {:command => command } unless command.nil?
			end
		end
		result
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
