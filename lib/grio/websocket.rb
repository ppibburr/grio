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
    
    def self.connect h,p,uri: "", headers: {},&b
      GLibRIO.connect_web_socket h,p,uri: uri,headers: headers,&b
    end
        
    module ServerSocket
      include GLibRIO::WebSocket
      def driver
        @driver ||= ::WebSocket::Driver.server(self)
      end
    end
    
    module ClientSocket
      include GLibRIO::WebSocket
      def driver &b
        @driver ||= ::WebSocket::Driver.client(self)
        
        # @driver.add_extension PermessageDeflate if !@init
        
        b.call(@driver) if b
        
        @driver.start if is_a?(ClientSocket) and !@init
        
        @init = true
        
        @driver
      end
    end
    
    def url
      @uri
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
    attr_accessor :headers, :uri
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
  
  def self.connect_web_socket h,p, uri: "", headers: {},&b
    wsc = connect h,p do |wsc|
      wsc.extend(WebSocketClient)      
        wsc.uri = uri == "" ? "ws://#{h}:#{p}" : uri

        wsc.driver do |d|
          headers.each_pair do |hd, v|
           d.set_header hd.to_s,v.to_s
        end
      end
    
      wsc.listen do |data|
        wsc.driver.parse data  
      end    
    
      b.call wsc if b
    end
    
    wsc
  end
end
