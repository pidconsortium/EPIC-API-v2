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
	open(@debug_path, 'a') { |dfile|  dfile.puts msg }
   end

 
   def debug(msg)

     if @enabled == true
	  open(@debug_path, 'a') { |dfile|  dfile.puts msg }
     end
   
   end

   private_class_method :new

end

end
