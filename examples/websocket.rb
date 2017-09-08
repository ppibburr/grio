begin
  require "grio/dsl"
rescue LoadError
  $: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib","grio"))
  require 'grio'
  require 'grio/dsl'
end

require 'grio/websocket'

require 'grio/dsl'
require 'grio/websocket'

grio.run do |loop|
  grio.web_socket.serve "0.0.0.0",2222 do |s|
    s.on :connect do
      s.puts "Welcome!"
    end
  
    s.on :message do |e|
      puts "Server rcvd msg: #{e.data}"
    end
  end
  
  grio.web_socket.connect "0.0.0.0",2222 do |s|
    s.on :message do |e| 
      puts "Client rcvd msg: #{e.data}"
    
      grio.timeout 1000 do        
        grio.quit
        
        false
      end
    end
    
    s.on :open do
      s.puts "Hello"
    end
  end
end

