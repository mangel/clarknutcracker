module Data

	class InMemoryManager
		@storage=nil

		def initialize()
		end

		def add_entry(key, value)
		end

		def delete(key)
		end

		def replace(key, new_data)
		end

		def notify()
		end
	end

	class InMemoryStorage
		@entries=nil

		def initialize()
			@entries=Hash.new
		end

		def add(key, value)

		end

		def delete(key)

		end

		def replace(key, new_data)

		end
	end

	class InMemoryEntry
		@key=nil
		@value=nil
		@state=nil
		@register_date=nil
		@revision=nil

		def initialize(key, value)
			@key = key
			@value = value
		end
	end
end
