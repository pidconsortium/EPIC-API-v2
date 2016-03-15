# Copyright ©2011-2012 Pieter van Beek <pieterb@sara.nl>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'epic_debugger.rb'
require 'epic_collection.rb'
require 'epic_sequel.rb'


module EPIC


class Handles < Collection


  def prefix
      Debugger.instance.debug("epic_handles.rb:#{__LINE__}:prefix")
     @epic_handles_prefix ||= File::basename(path.unslashify).to_path.unescape
  end


  # @todo better implementation (server-side data retention) for streaming responses.
  def each
    Debugger.instance.debug("epic_handles.rb:#{__LINE__}:each")
    query = Rackful::Request.current.GET.dup
    if limit = query['limit']
      query.delete('limit')
      if (limit = limit.to_i) < 0
        raise Rackful::HTTP400BadRequest, "Query parameter 'limit' must be greater than or equal to zero."
      end
    else
      limit = 1000
    end
    if page = query['page']
      query.delete('page')
      if (page = page.to_i) < 1
        raise Rackful::HTTP400BadRequest, "Query parameter 'page' must be greater than zero."
      end
    else
      page = 1
    end
    start_position = self.prefix.size + 1
    if query.empty?
      DB.instance.each_handle( self.prefix, limit, page ) do
        |handle|
        yield( ( self.path + escape_path( handle[start_position .. -1] ) ).to_path )
      end
    else
      filter = []
      query.each_pair do
        |k,v|
        if String == v.class
          filter.push( [k, v] )
        else
          v.each { |v2| filter.push( [k, v2] ) }
        end
      end
      DB.instance.each_handle_filtered( self.prefix, filter, limit, page ) do
        |handle|
        yield( ( self.path + escape_path( handle[start_position .. -1] ) ).to_path )
      end
    end
  end


  add_media_type 'application/json', :POST
  add_media_type 'application/x-json', :POST


  # Handles an HTTP/1.1 PUT request.
  # @see Rackful::Resource#do_METHOD
  def do_POST request, response
    Debugger.instance.debug("epic_handles.rb:#{__LINE__}:do_POST")
    generator_name = request.GET['generator'] || EPIC::DEFAULT_GENERATOR
    unless generator = request.resource_factory["/generators/#{generator_name}"]
      raise Rackful::HTTP400BadRequest, "No such generator: '#{generator_name}'"
    end
    generate_suffix = true
    while(generate_suffix)
      pid_suffix = escape_path( generator.generate( request ) )
      Debugger.instance.debug("epic_handles.rb:#{__LINE__}:generating suffix")
      handle = request.resource_factory["/handles/#{prefix}/#{pid_suffix}"]
      if (handle.empty?)
        Debugger.instance.debug("epic_handles.rb:#{__LINE__}:PID not exsiting #{pid_suffix}")
        generate_suffix = false
      else
         Debugger.instance.debug("epic_handles.rb:#{__LINE__}:WARINING #{pid_suffix} IS EXISTING ... generate new one")
      end
    end
    handle.do_PUT( request, response )
  end

end # class Handles


end # module EPIC
