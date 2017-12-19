require "glib2"
require 'socket'

require File.expand_path(File.join(File.dirname(__FILE__), "..", "grio"))

module GLibRIO
  module DSL
    def grio
      GLibRIO
    end
    
    def socket
      grio::Socket
    end
  end

  extend DSL

  def self.read_nonblock socket=STDIN,recv: false, max: 1024, &b
    GLib::Idle.add do
      begin
        if (a = IO.select([socket],[],[],0))
          data = recv ? a[0][0].recv(max) : a[0][0].gets
          b.call data
        end
      rescue => e;
        if socket.respond_to?(:on_err)
          next socket.on_err(e)
        else
          raise e
        end
      end
        
      true
    end  
  end
  
  def self.read socket=STDIN, recv: false, max: 1024, &b
    read_nonblock socket, recv: recv, max: max, &b
  end
  
  module Socket
    def listen recv: false, max: 1024, &b
      GLibRIO.read_nonblock self, recv: recv, max: max do |data|
        on_recv data, &b
      end
    end
    
    def on_err e
      raise e
    end
    
    def on_recv data, &b
      b.call data if b
    end
    
    def self.serve h,p,&b
      GLibRIO.serve h,p,&b
    end
    
    def self.connect h,p,&b
      GLibRIO.connect h,p,&b
    end
  end
  
  class TCPClient < TCPSocket
    include GLibRIO::Socket
    attr_reader :host,:port
    def initialize host, port
      super host,port
      @host = host
      @port = port
    end
  end
  
  def self.run singleton=true, &b
    loop = GLib::MainLoop.new
    @main_loop = loop if singleton
    b.call loop if b
    loop.run
  end
  
  def self.quit loop = @main_loop
    loop.quit if loop
  end
  
  def self.connect host,port, &b
    client = TCPClient.new host,port
    b.call client if b
    client
  end
  
  def self.serve host, port, &b
    server = GLibRIO::TCPServer.new(host,port, b)
  end
  
  class TCPServer < ::TCPServer
    def initialize h,p, b
      super(h,p)
      
      GLib::Idle.add do
        begin
        if socket = accept_nonblock
          socket.extend GLibRIO::Socket
          b.call socket
        end
        rescue IO::WaitReadable, Errno::EINTR => e
        end
        true
      end
    end
  end
  
  def self.timeout rate, &b
    GLib::Timeout.add rate, &b
  end
  
  def self.idle &b
    GLib::Idle.add &b
  end
end

if __FILE__ == $0
  include GLibRIO::DSL
  
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
end
