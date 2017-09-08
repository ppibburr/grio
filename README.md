# grio
Glib2 Ruby Async Socket Library

TCP Server / Client Example
===
```ruby
require 'grio/dsl'

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

```

WebSocket Server / Client Example
===
```ruby
require 'grio/dsl'
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
```
