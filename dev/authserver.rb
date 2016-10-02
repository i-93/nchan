#!/bin/ruby
require "pry"
require 'celluloid/current'
require 'celluloid/logger'
require "rack"
require "reel/rack/cli"
require 'reel/rack'
require "optparse"

def print_request(env)
  out = []
  out << "  #{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}"
  out << "  Host: #{env["HTTP_HOST"]}"
  env.each do |k,v|
    if k != "  HTTP_HOST" && k =~ /^HTTP_/
      out << "  #{k.split("_").slice(1..-1).each(&:capitalize!).join('-')}: #{v}"
    end
  end
  puts out.join("\n")
end

class AuthServer
  if __FILE__ != $PROGRAM_NAME
    include Celluloid::IO
  end
  attr_accessor :app
  def initialize(opt={})
    @opt = opt || {}
    @opt[:Port] ||= 8053
    
    @app = proc do |env|
      resp = []
      headers = {}
      code = 200
      body = env["rack.input"].read
      
      print_request env if @opt[:verbose]
      
      case env["REQUEST_PATH"] || env["PATH_INFO"]
      when "/accel_redirect"  
        chid="foo"
        headers["X-Accel-Redirect"]="/sub/internal/#{chid}"
        headers["X-Accel-Buffering"] = "no"
      when "/auth"
        #meh
      when "/auth_fail"
        code = 403
      when "/sub"
        resp << "subbed"
      when "/pub"
        resp << "pubbed"
      when "/pub"
        resp << "WEE! + #{body}"
      end
      
      headers["Content-Length"]=resp.join("").length.to_s
      
      [ code, headers, resp ]
    end
  end
  
  def run
    Rack::Handler::Reel.run(app, @opt)
  end
end



if __FILE__ == $PROGRAM_NAME then
  opt = {}
  opt_parser=OptionParser.new do |opts|
    opts.on("-q", "--quiet", "Be quiet!"){ opt[:quiet] = true}
    opts.on("-v", "--verbose", "Be loud."){ opt[:verbose] = true}
  end
  opt_parser.parse!
  
  auth = AuthServer.new opt
  auth.run
end
