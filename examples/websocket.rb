begin
  require "grio/dsl"
rescue LoadError
  $: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib","grio"))
  require 'grio'
  require 'grio/dsl'
end

require 'grio/websocket'

grio.run do |loop|
  grio.web_socket.serve "0.0.0.0",2222 do |s|
    s.on :connect do
      p "Connected from"
      s.puts "test"
    end
  
    s.on :message do |e|
      puts "RECV: "+e.data
     
      s.puts e.data
    end
  end
  
  grio.web_socket.connect "0.0.0.0",2222 do |s|
    s.on :message do |e| 
      puts "Client RECV: "+e.data 
      
      grio.timeout 333 do
        s.puts Time.now.to_s
        false
      end
    end
    
    s.on :open do
      s.puts "MSG FROM CLI"
    end
  end
end
