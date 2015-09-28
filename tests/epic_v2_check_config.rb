#!/usr/bin/env ruby
require_relative '../src/epic_checkconfig.rb'
require_relative '../config.rb'
require_relative '../secrets/users.rb'

puts "---- EPIC-API-v2 CONFIG Check -----\n\n"
puts "Checking API Config-File for validity...\n\n"

pass = true

begin
 check_config = EPIC::CheckConfig.instance()
rescue Exception => e
  puts "Details:\n\n#{e.message}\n\n"
  pass = false
ensure
  puts pass ? "Config Check finished successfully." : "Config Check failed." 
end

