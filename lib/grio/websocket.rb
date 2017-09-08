require 'websocket/driver'

require File.expand_path(File.join(File.dirname(__FILE__), "..", "grio"))

module GLibRIO
  module DSL
    def web_socket
      GLibRIO::WebSocket
    end
  end
  module WebSocket
    def self.serve h,p,&b
      GLibRIO.serve_web_socket h,p,&b
    end
    
    def self.connect h,p,&b
      GLibRIO.connect_web_socket h,p,&b
    end
        
    module ServerSocket
      include GLibRIO::WebSocket
      def driver
        @driver ||= ::WebSocket::Driver.server(self)
      end
    end
    
    module ClientSocket
      include GLibRIO::WebSocket
      def driver
        @driver ||= ::WebSocket::Driver.client(self)
        # @driver.add_extension PermessageDeflate if !@init
        @driver.start if is_a?(ClientSocket) and !@init
        @init = true
        @driver
      end
    end    

    def driver

    end
    
    def on type, &b
      driver.on(type) do |*o|
        driver.start if type == :connect && ::WebSocket::Driver.websocket?(driver.env)
        b.call *o
      end
    end

    def puts s
      driver.text s
    end
    
    def listen max: 1024, &b
      super recv: true, max: max, &b
    end
  end
  
  module WebSocketServer 
  end
  
  module WebSocketClient
    include WebSocket::ClientSocket
    def url
      "ws://#{host}:#{port}"
    end
  end
  
  def self.serve_web_socket h,p,&b
    wss = serve h,p do |s|
      s.extend WebSocket::ServerSocket
      
      s.listen do |data|
        s.driver.parse data
      end
      
      b.call s
    end.extend WebSocketServer
  end
  
  def self.connect_web_socket h,p, &b
    wsc = connect h,p do |wsc|
      wsc.extend(WebSocketClient)
    
      wsc.listen do |data|
        wsc.driver.parse data  
      end    
    
      b.call wsc if b
    end
    
    wsc
  end
end

if __FILE__ == $0
  include GLibRIO::DSL
  
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
end
