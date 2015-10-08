require 'singleton'
require '../config.rb'
module EPIC

class Debugger

    attr_reader :debug_path, :enabled
      
   include Singleton
 
   def initialize
        @debug_path = DEBUG_SETTINGS[:debug_path]
        @enabled = DEBUG_SETTINGS[:enabled]
   end
  
   
   def log(msg)
 	request = Rackful::Request.current
        env = request.instance_variable_get(:@env)
        now = Time.now
        if (env != nil)
                output_msg = "[" +
                        now.strftime("%d/%b/%Y:%H:%M:%S %z") + "]  #{env['REQUEST_METHOD']} from #{env['REMOTE_USER']}@#{env['REMOTE_ADDR']} on #{env['PATH_INFO']}  >> #{msg}."
        else
                output_msg = "initialization..."
        end

	open(@debug_path, 'a') { |dfile|  dfile.puts output_msg }
   end

   def debug(msg)
   	request = Rackful::Request.current
   	env = request.instance_variable_get(:@env)
   	now = Time.now
   	if (env != nil)
   	 output_msg = "[" +                        
                 now.strftime("%d/%b/%Y:%H:%M:%S %z") + "]  #{env['REQUEST_METHOD']} from #{env['REMOTE_USER']}@#{env['REMOTE_ADDR']} on #{env['PATH_INFO']}  >> #{msg}."
        else
   		output_msg = "initialization..."
  	end
   	
	if @enabled == true
        	  open(@debug_path, 'a') { |dfile|  dfile.puts output_msg }
     	end

   end

   private_class_method :new

end

end
