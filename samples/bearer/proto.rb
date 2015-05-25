module Proto
	require 'securerandom'
	require 'net/http'

	def Proto.send_post(url, data, header)
		uri = URI.parse(url)
		req = Net::HTTP::Post.new(uri, initheader = header)
		req.body = data
		res = Net::HTTP.start(uri.hostname, uri.port) do |http|
			http.request(req)
		end
		return res
	end
end
