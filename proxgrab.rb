require 'socket'
require 'thread'
require 'net/http'
require 'timeout'

threads = []
$timeout = 10
$raw = false

class Helper
	def initialize
	end
	
	def Banner
			print("\n\t# ProxyGrab 0.2 by Bonkers #\n\n")
	end
	
	def Help
		print("Options:\n\n-t 5    Proxy-Timeout in Seconds\n-r      Raw-Output (IP:Port, sorted by response-time)\n-h      Shows this help\n")
		exit(0)
	end

	def Args
		ARGV.each_with_index do |arg, index|
			if arg == "-t"
				$timeout = ARGV[index + 1]
			elsif arg == "-h"
				self.Help()
				exit(0)
			elsif arg == "-r"
				$raw = true
			end
		end
	end
end


class Proxgrab
	def initialize
	end
	
	def AntiBotToken
	
		res = Net::HTTP.start('www.proxy-listen.de', 80) {|http|
			http.get('/Proxy/Proxyliste.html')
		}
		if res.body =~ /<input name="z" value="(.+?)"/m
			return $~[1]
		else
			raise "Could not get security-token"
		end	
	end

	def Grab
		begin
			http = Net::HTTP.new('www.proxy-listen.de', 80)
			data = "filter_port=&filter_http_gateway=&filter_http_anon=&filter_response_time_http=5&z=#{self.AntiBotToken()}&filter_country=US&filter_timeouts1=&liststyle=leech&proxies=300&type=http&submit=Anzeigen"
			resp, data = http.post('/Proxy/Proxyliste.html', data)
			body = resp.body()
			result = body.scan(/<a class="proxyList".+?target="_blank">(.+?):(.+?)<\/a>/m)
			return result
		rescue
			raise "Could not download the proxy-list"
		end
	end
end
class Proxtest
	def initialize
	end
	def Test(ip, port)
		begin
			timeout($timeout.to_i) do
				start_time = Time.now.to_f
				client = TCPSocket.new(ip, port)
				ip_services = [ "GET http://checkip.dyndns.org HTTP/1.1\r\nHost: checkip.dyndns.org\r\nConnection: close\r\n\r\n", "GET http://myip.is HTTP/1.1\r\nHost: myip.is\r\nConnection: close\r\n\r\n" ]
				client.puts ip_services[rand(2)]
				answer = client.gets(nil)
				if answer =~ /(Current|Hostname)/
					temp = "#{ip}:#{port}"
					if $raw == true
						puts(temp)
					else
						puts("#{temp}#{" "*(26-temp.length)}OK      #{(Time.now.to_f-start_time).round(2)}")
					end
				else
				end
			end
		rescue Timeout::Error
			exit!
		rescue
		end
	end
end

hp = Helper.new
pg = Proxgrab.new

hp.Banner()
hp.Args()

check_us = pg.Grab()

if !$raw
	puts("#{check_us.length} Proxies grabbed. Checking them.\n")
	puts("\nIP:Port#{" "*19}HTTP#{" "*4}Time\n\n")
end
check_us.each do |proxy|
		threads << Thread.new(proxy){ |proxy|
		pt = Proxtest.new
		pt.Test(proxy[0], proxy[1])
		}
end

threads.each { |prxThread| 
				prxThread.join
}


