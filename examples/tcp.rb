begin
  require "grio/dsl"
rescue LoadError
  $: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib","grio"))
  require 'grio'
  require 'grio/dsl'
end

grio.run do
  grio.socket.serve "0.0.0.0", 2222 do |socket|
    socket.listen do |data|
      socket.puts data
    end
  end
  
  grio.socket.connect "0.0.0.0",2222 do |socket|
    socket.listen do |data|
      puts "Client revieved: #{data}"
      grio.timeout 1000 do
        grio.quit
      end
    end
    
    socket.puts "test"
  end
end
