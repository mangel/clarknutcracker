class Settings
	@@settings=
	{
		:access_list => [
			{ :hostname => 'host_a', :key => 'xxx' }
		]
	}
	def self.settings()
		return @@settings
	end
end
