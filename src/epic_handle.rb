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
require 'epic_json_response.rb'
require 'epic_collection.rb'
require 'epic_sequel.rb'
require 'epic_hs.rb'
require 'base64'
require 'digest'
require 'time'
require 'json'

# By default, the json gem uses the +Ext+ parser and generator, which uses a
# fast Java implementation. We use the +Pure+ parser and generator, because it
# seems to handle Unicode characters better. This is strange, as these two
# implementations should behave identically.
require 'json/pure'

module EPIC
  class Handle < Resource

    # The prefix of this Handle
    # @return [String]
    attr_reader :prefix

    # The suffix of this Handle
    # @return [String]
    attr_reader :suffix

    # The entire handle, {#prefix} <tt>"/"</tt> {#suffix}
    # @return [String]
    def handle
      Debugger.instance.debug("epic_handle.rb:#{__LINE__}:handle")
      "#{prefix}/#{suffix}"
    end

    # The URI-encoded handle as it was received by the server.
    # @return [String]
    attr_reader :handle_encoded

    def initialize path, handle_values = nil
      super path
      Debugger.instance.debug("epic_handle.rb:#{__LINE__}:initialze")
      unless matches = %r{([\d]+(?:\.[^/]+)*)/([^/]+)\z}.match(path)
        raise "Unexpected path: #{path}"
      end
      @suffix = matches[2].to_path.unescape
      @prefix = matches[1].to_path.unescape
      @handle_encoded = matches[0]
      self.values handle_values if handle_values
    end

    # @!attribute values [r]
    # @param dbrows [Array<Hash>] only used by {#initialize}. This is an
    #   implementation detail.
    # @return [ Array<HandleValue> ]
    def values dbrows = nil
      rows = (
        dbrows || DB.instance.all_handle_values(self.handle)
      ).collect { |row| HandleValue.new row }
        if rows.size < 1
          Debugger.instance.debug("epic_handle.rb:#{__LINE__}:Handle: #{self.handle} not found")
        end
      @values ||=  rows
    end

    add_media_type 'application/json'
    add_media_type 'application/x-json'

    # Handles an HTTP/1.1 PUT request.
    # @see Rackful::Resource#do_METHOD
    def do_PUT request, response
      begin
        handle_values_in = Rackful::JSON.parse( request.body )
      rescue
        raise Rackful::HTTP400BadRequest, $!.to_s
      end # begin
      unless handle_values_in.kind_of? Array
        raise Rackful::HTTP400BadRequest, 'Array expected'
      end
      new_values = handle_values_in.collect do
        |handle_value_in|
        handle_value = HandleValue.new
        if handle_value_in.key? :idx
          handle_value.idx = handle_value_in[:idx].to_i
        end
        if handle_value_in.key? :type
          handle_value.type = handle_value_in[:type].to_s
        end
        if handle_value_in.key? :data
          handle_value.data = Base64.decode64( handle_value_in[:data].to_s )
        end
        
        if handle_value_in.key?( :data ) &&
           handle_value_in.key?( :parsed_data )
          data = handle_value.data
          parsed_data = handle_value.parsed_data
          handle_value.parsed_data = handle_value_in[:parsed_data]
          unless data == handle_value.data ||
                 parsed_data == handle_value.parsed_data
            raise Rackful::HTTP400BadRequest, 'Handle Value contains both <tt>data</tt> and <tt>parsed_data</tt>, and their contents are not semantically equal.'
          end # unless
        elsif handle_value_in.key?( :parsed_data )
          handle_value.parsed_data = handle_value_in[:parsed_data]
        end # if
        if handle_value_in.key? :ttl_type
          handle_value.ttl_type = handle_value_in[:ttl_type].to_i
        end
        if handle_value_in.key? :ttl
          handle_value.ttl = handle_value_in[:ttl].to_i
        end
        if handle_value_in[:refs].kind_of?( Array ) &&
            handle_value_in[:refs].all? do
              |ref|
              ref.kind_of?( Hash ) &&
              ref[:idx].kind_of?( Integer ) &&
              ref[:handle].kind_of?( String )
            end
          handle_value.refs = handle_value_in[:refs]
        end
        if handle_value_in.key? :admin_read
          handle_value.admin_read = !!handle_value_in[:admin_read]
        end
        if handle_value_in.key? :admin_write
          handle_value.admin_write = !!handle_value_in[:admin_write]
        end
        if handle_value_in.key? :pub_read
          handle_value.pub_read = !!handle_value_in[:pub_read]
        end
        if handle_value_in.key? :pub_write
          handle_value.pub_write = !!handle_value_in[:pub_write]
        end
        handle_value
      end # values = handle_values_in.collect do
      self.class.enforce_proper_indexes new_values
      self.class.enforce_admin_record new_values, request.env['REMOTE_USER']
      self.lock
      begin
        @values = nil
        if self.empty?
          Profile.profiles.each do
            |profile_name, profile|
            if tmp = profile.create( request, self.prefix, self.suffix, new_values )
               Debugger.instance.debug("epic_handle.rb:#{__LINE__}:Profile #{profile_name} enforced for Creating Handle.")
               new_values = tmp
            end
          end
          HS.create_handle(self.handle, new_values, request.env['REMOTE_USER'])
          Debugger.instance.debug("epic_handle.rb:#{__LINE__}:Handle created | PUT")
          accept_keys = request.accept.keys
          json_resp = false
          accept_keys.each do |key|
             if key == 'application/json'
               if request.accept[key]  == 1
                  json_resp = true
               end
             end
          end
          if json_resp == true
            Eresponse.new response, self
         else
           raise Rackful::HTTP201Created, self.path
         end
        else
          old_values = self.values
          Profile.profiles.each do
            |profile_name, profile|
            if tmp = profile.update( request, self.prefix, self.suffix, old_values, new_values )
              Debugger.instance.debug("epic_handle.rb:#{__LINE__}:Profile #{profile_name} enforced for Updating Handle.")
              new_values = tmp
            end
          end
          HS.update_handle(self.handle, self.values, new_values, request.env['REMOTE_USER'])
          @values = nil
          Debugger.instance.debug("epic_handle.rb:#{__LINE__}:Handle updated | PUT")
          response.status = status_code(:no_content)
        end
      ensure
        Debugger.instance.debug("-----------------------------------------------------")
        self.unlock
      end
    end

    # @see Rackful::Resource#do_Method
    # @todo This documentation sucks!
    def destroy request, response
      Profile.profiles.each do |profile_name, profile|
        Debugger.instance.debug("epic_handle.rb:#{__LINE__}:Profile #{profile_name} enforced for Deleting Handle.")
        profile.delete request, self.prefix, self.suffix, self.values
      end
      HS.delete_handle self.handle, request.env['REMOTE_USER']
      @values = nil
      response.status = status_code(:no_content)
      Debugger.instance.debug("epic_handle.rb:#{__LINE__}:Handle deleted | DELETE")
      nil
    end

    # Make sure each value has a proper, unique index.
    #
    # Clients may upload a set of handle values without indexes. If that happens,
    # {#do_PUT} gives these handles the default index. This method makes sure each
    # handle value is properly indexed.
    # @param values [Array<HandleValue>]
    # @return [Array<HandleValue>] values
    def self.enforce_proper_indexes values
      all_indexes = []
      values.each do
        |value|
        next if HS::EMPTY_HANDLE_VALUE.getIndex == value.idx
        raise( Rackful::HTTP400BadRequest, "Multiple values with index #{value.idx}" ) \
        if all_indexes.member? value.idx
        all_indexes << value.idx
      end
      current_index = 1
      values.each do
        |value|
        next unless HS::EMPTY_HANDLE_VALUE.getIndex == value.idx
        current_index = current_index + 1 while all_indexes.member? current_index
        value.idx = current_index
        all_indexes << current_index
      end
      values
    end

    # Adds an +HS_ADMIN+ value to a set of values if there isn't yet.
    # @param values [Array<HandleValue>]
    # @param user_name [String]
    # @return [Array<HandleValue>] values
    # @todo I found a Java method +GenericHSAdapter#createAdminValue+ that
    #   does exactly what we need! Use that instead! ---PvB
    def self.enforce_admin_record values, user_name
      unless values.any? { |v| 'HS_ADMIN' === v.type }
        idx = 100
        idx += 1 while values.any? { |v| idx === v.idx }
        # In the JAVA code for the standard CNRI adminTool, the following code can
        # be found in private method +MainWindow::getDefaultAdminRecord()+:
        #
        #   adminInfo.perms[AdminRecord.DELETE_HANDLE] = true;
        #   adminInfo.perms[AdminRecord.ADD_VALUE] = true;
        #   adminInfo.perms[AdminRecord.REMOVE_VALUE] = true;
        #   adminInfo.perms[AdminRecord.MODIFY_VALUE] = true;
        #   adminInfo.perms[AdminRecord.READ_VALUE] = true;
        #   adminInfo.perms[AdminRecord.ADD_ADMIN] = true;
        #   adminInfo.perms[AdminRecord.REMOVE_ADMIN] = true;
        #   adminInfo.perms[AdminRecord.MODIFY_ADMIN] = true;
        #   adminInfo.perms[AdminRecord.ADD_HANDLE] = true;
        #   adminInfo.perms[AdminRecord.LIST_HANDLES] = false;
        #   adminInfo.perms[AdminRecord.ADD_NAMING_AUTH] = false;
        #   adminInfo.perms[AdminRecord.DELETE_NAMING_AUTH] = false;
        #   return makeValueWithParams(100, Common.STD_TYPE_HSADMIN,
        #                              Encoder.encodeAdminRecord(adminInfo));
        user_info = EPIC::USERS[user_name]
        admin_record = HandleValue.new
        admin_record.idx = idx
        admin_record.type = 'HS_ADMIN'
	admin_record.parsed_data = {
          :adminId => user_info[:handle_create] || user_info[:handle],
          :adminIdIndex => user_info[:index_create] || user_info[:index],
          :perms => HS::DEFAULT_PERMS
         }
        values << admin_record
      end
      values
    end

    # @return [ Array< Hash > ]
    def to_rackful
      self.values.sort_by { |v| v.idx }.collect {
        |v|
        {
          :idx => v.idx,
          :type => v.type,
          :parsed_data => v.parsed_data,
          :data => v.data,
          :timestamp => Time.at(v.timestamp),
          :ttl_type => v.ttl_type,
          :ttl => ( 0 == v.ttl_type ? v.ttl : Time.at( v.ttl ) ),
          :refs => v.refs.collect { |ref| ref[:idx].to_s + ':' + ref[:handle] },
          :privs =>
          ( v.admin_read  ? 'r' : '-' ) +
          ( v.admin_write ? 'w' : '-' ) +
          ( v.pub_read    ? 'r' : '-' ) +
          ( v.pub_write   ? 'w' : '-' )
        }
      }
    end

    # @return [Boolean]
    # @see Rackful::Resource#empty?
    def empty?
      self.values.empty?
    end

    # @return [Time]
    # @see Rackful::Resource#last_modified
    def get_last_modified
      [
        Time.at(
        self.values.reduce(0) do
        |memo, value|
        value.timestamp > memo ? value.timestamp : memo
        end
        ),
        false # to indicate that this is _not_ a strong validator.
      ]
    end

    # @return [String]
    # @see Rackful::Resource#etag
    def get_etag
      retval = self.values.sort_by do
        |value| value.idx
      end.reduce(Digest::MD5.new) do
        |digest, value|
        digest <<
        value.idx.inspect <<
        value.type.inspect <<
        value.data.inspect <<
        value.refs.inspect <<
        value.ttl.inspect <<
        value.ttl_type.inspect <<
        value.admin_read.inspect <<
        value.admin_write.inspect <<
        value.pub_read.inspect <<
        value.pub_write.inspect
      end.to_s
      retval = [ retval ].pack('H*')
       Debugger.instance.debug("epic_handle.rb:#{__LINE__}:Handle.get_etag sent HTTP-etag: " + "'" + Base64.strict_encode64(retval)[0..-3] + "' to client")
       '"' + Base64.strict_encode64(retval)[0..-3] + '"'     
    end
  
  end # class Handle

  class Handle::XHTML < Rackful::XHTML
    def each_nested # :yields: strings
      values = self.resource.to_a
      values.each do
        |value|
        value[:timestamp] = Time.at(value[:timestamp]).utc.xmlschema
        value[:ttl] = ( 0 == value[:ttl_type] ) ?
        value[:ttl].to_s + 's' :
        Time.at(value[:ttl]).utc.xmlschema
        value.delete :ttl_type
        value[:perms] =
        ( value[:admin_read]  ? 'r' : '-' ) +
        ( value[:admin_write] ? 'w' : '-' ) +
        ( value[:pub_read]    ? 'r' : '-' ) +
        ( value[:pub_write]   ? 'w' : '-' )
        value.delete :admin_read
        value.delete :admin_write
        value.delete :pub_read
        value.delete :pub_write
      end
      yield self.serialize values
    end

  end # class Collection::XHTML

  class Handle::JSON < Rackful::JSON
    def each
      yield ::JSON::pretty_generate( self.resource.to_a )
    end

  end # class Handle::JSON

end # module EPIC
