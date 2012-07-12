=begin License
  Copyright ©2011-2012 Pieter van Beek <pieterb@sara.nl>
  
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  
      http://www.apache.org/licenses/LICENSE-2.0
  
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
=end


require 'java'
require 'hsj/handle.jar'
require 'hsj/cnriutil.jar'


module EPIC


=begin rdoc
Namespace for everything related to the Handle System client library (Java).

This module is not object-oriented; it's just a collection of "procedures" that
wrap around bits of the Handle client library.
=end
module HS


  # A shorthand for the Java +net.handle.hdllib+ package.
  HDLLIB = Java::NetHandleHdllib

  # All permissions in the Handle System, indexed by integers.
  PERMS_BY_I = [
    :add_handle,          #  0
    :delete_handle,       #  1
    :add_naming_auth,     #  2
    :delete_naming_auth,  #  3
    :modify_value,        #  4
    :remove_value,        #  5
    :add_value,           #  6
    :read_value,          #  7
    :modify_admin,        #  8
    :remove_admin,        #  9
    :add_admin,           # 10
    :list_handles         # 11
  ]

  # All permissions in the Handle System, indexed by symbols.
  PERMS_BY_S = Hash[ PERMS_BY_I.each_with_index.to_a ]

  # These constants need to be the same as in Java.
  # Let's check if they are:
  unless PERMS_BY_S.all? {
           |symbol, integer|
           integer == HDLLIB.AdminRecord.const_get( symbol.to_s.upcase.to_sym )
         }
    raise 'Oops! CNRI changed their constants!'
  end

  # Cache of Java +AuthenticationInfo+ objects, indexed by user name.
  AUTHINFO = {}

=begin rdoc
Mutex used to make some of the methods in this class thread-safe.
@see HS.resolver
@see HS.authentication_info
=end
  MUTEX = Mutex.new
  EMPTY_HANDLE_VALUE = HDLLIB::HandleValue.new


class << self


=begin rdoc
@!method unpack_SOME_HANDLE_TYPE(data)
Translates binary data (from the database) to a Ruby structure.

For certain binary encoded Handle value types, like +HS_ADMIN+ and +HS_VLIST+,
the web service can produce <em>and consume</em> a structured representation.
For example, the +JSON+ representation of an +HS_ADMIN+ value looks like this
(abbreviated and prettified for clarity):

  {
    "idx"        : 100,
    "type"       : "HS_ADMIN",
    "data"       : "D/8AAAAKMC5OQS8xMTAyMgAAASwAAA==",
    "parsed_data": {
      "adminId"     : "0.NA/11022",
      "adminIdIndex": 300,
      "perms"       : {
           "add_handle": true,     "add_naming_auth": true,
        "delete_handle": true,  "delete_naming_auth": true,
         "modify_value": true,        "modify_admin": true,
         "remove_value": true,        "remove_admin": true,
            "add_value": true,           "add_admin": true,
           "read_value": true,        "list_handles": true
      }
    }
  }

To add a new "parseble" type to this web service, all you have to do is create
two new methods in this module, called
{unpack_SOME_HANDLE_TYPE unpack_YOUR_TYPE} and
{pack_SOME_HANDLE_TYPE pack_YOUR_TYPE}, which translate between the binary and
the structured representations.

<b>See also:</b>::
  {HandleValue#parsed_data} and {HandleValue#parsed_data=} which use
  introspection to find out if a parsed representation of a value type
  is available.
@param data [String] some binary data.
@return [Hash] a structured representation of +data+
=end


=begin rdoc
@!method pack_SOME_HANDLE_TYPE(data)
Translates a Ruby structure into binary data.
@return [String] a binary representation of +data+
@param data [Hash] some structured data
@see #unpack_SOME_HANDLE_TYPE
=end


=begin rdoc
@param data [String]
@return [Hash]
@see #unpack_SOME_HANDLE_TYPE
=end
  def unpack_HS_ADMIN data
    adminRecord = HDLLIB::AdminRecord.new
    HDLLIB::Encoder.decodeAdminRecord(
      data.to_java_bytes, 0, adminRecord
    )
    perms = adminRecord.perms.to_a
    {
      :adminId => String.from_java_bytes( adminRecord.adminId ),
      :adminIdIndex => adminRecord.adminIdIndex,
      :perms => Hash[
        perms.each_index.collect {
          |i|
          [ PERMS_BY_I[i].to_s.downcase, perms[i] ] 
        }
      ]
    }
  end


=begin rdoc
@param data [Hash]
@return [String]
@see #pack_SOME_HANDLE_TYPE
=end
  def pack_HS_ADMIN data
    raise ReST::HTTPStatus, "BAD_REQUEST Missing one or more required values: #{data.inspect}" \
      if ! data.kind_of?( Hash ) ||
         ! data[:adminId] ||
         ! data[:adminIdIndex] ||
         ! data[:perms] ||
         ! data[:perms].kind_of?( Hash ) ||
         ! PERMS_BY_I.all? {
             |perm|
             data[:perms].key? perm.to_s.downcase.to_sym
           }
    adminRecord = HDLLIB::AdminRecord.new
    adminRecord.adminId = data[:adminId].to_s.to_java_bytes
    adminRecord.adminIdIndex = data[:adminIdIndex].to_i
    adminRecord.perms = PERMS_BY_I.collect do
      |perm|
      !! data[:perms][ perm.to_s.downcase.to_sym ]
    end.to_java Java::boolean
    String.from_java_bytes(
      HDLLIB::Encoder.encodeAdminRecord( adminRecord )
    )
  end


=begin rdoc
@param data [String]
@return [Hash]
@see #unpack_SOME_HANDLE_TYPE
=end
  def unpack_HS_VLIST data
    vlist = HDLLIB::Encoder.decodeValueReferenceList(
      data.to_java_bytes, 0
    )
    vlist.to_a.collect do
      |ref|
      { :idx => ref.index, :handle => String.from_java_bytes( ref.handle ) }
    end
  end


=begin rdoc
@param data [Hash]
@return [String]
@see #pack_SOME_HANDLE_TYPE
=end
  def pack_HS_VLIST data
    raise 'Bad HS_VLIST data.' \
      if ! data.kind_of?( Array ) ||
         ! data.all? {
           |ref|
           ref.kind_of?(Hash) &&
           ref[:idx] &&
           ref[:idx].respond_to?(:to_i) &&
           ref[:handle] &&
           ref[:handle].respond_to?(:to_s)
         }
    data = data.collect do
      |ref|
      HS::HDLLIB::ValueReference.new(
        ref[:handle].to_s.to_java_bytes,
        ref[:idx].to_i
      )
    end.to_java HS::HDLLIB::ValueReference
    String.from_java_bytes(
      HDLLIB::Encoder.encodeValueReferenceList( data )
    )
  end


=begin rdoc
HandleResolver should be thread safe, so there's only one of it.
=end
  def resolver
    unless class_variable_defined? :@@resolver
      MUTEX.synchronize do
        unless class_variable_defined? :@@resolver
          @@resolver = HDLLIB::HandleResolver.new
          sessionSetupInfo = HDLLIB::SessionSetupInfo.new nil
          clientSessionTracker = HDLLIB::ClientSessionTracker.new sessionSetupInfo
          @@resolver.setSessionTracker clientSessionTracker
        end
      end
    end
    @@resolver
  end


=begin rdoc
A Java AuthenticationInfo object for user +user_name+.

The objects are cached for efficiency, in class constant +AUTH_INFO+
@private
@param user_name [#to_s]
@return [HDLLIB::AuthenticationInfo]
=end
  def authentication_info user_name
    user_name = user_name.to_s
    unless AUTHINFO[user_name]
      userInfo = EPIC::USERS[user_name]
      raise "No user info found for user '#{user_name}'" unless userInfo
      MUTEX.synchronize do
        #TODO Public key authentication
        AUTHINFO[user_name] ||= HDLLIB::SecretKeyAuthenticationInfo.new(
          userInfo[:handle].to_java_bytes,
          userInfo[:index],
          userInfo[:secret].to_java_bytes,
          true
        )
      end
    end
    AUTHINFO[user_name]
  end


=begin
Create a Handle
@param handle [#to_s]
@param values [Array<HandleValue>]
@param user_name [#to_s]
@return [void]
@raise [ReST::HTTPStatus]
=end
  def create_handle handle, values, user_name
    values = values.collect do
      |value|
      value.handle_value
    end
    request = HDLLIB::CreateHandleRequest.new(
      handle.to_java_bytes,
      values.to_java( HDLLIB::HandleValue ),
      authentication_info( user_name )
    )
    response = resolver.processRequest( request )
    if response.kind_of? HDLLIB::ErrorResponse
      case response.responseCode
      when HDLLIB::ErrorResponse::RC_INSUFFICIENT_PERMISSIONS
        raise ReST::HTTPStatus, 'FORBIDDEN'
      else
        raise response.to_string
      end
    end
  end


=begin
Update a Handle
@param handle [#to_s]
@param old_values [Array<HandleValue>] The old values in +handle+.
@param new_values [Array<HandleValue>] The new values for +handle+.
@param user_name [#to_s]
@return [void]
@raise [ReST::HTTPStatus]
=end
  def update_handle handle, old_values, new_values, user_name
    authInfo = authentication_info( user_name )
    values_2b_added    = []
    values_2b_modified = []
    values_2b_removed  = []
    new_values.each do
      |new_value|
      # If the passed handle value is equal to the existing handle value in all
      # respects, and no timestamp is passed, then the old timestamp should be
      # used.
      old_value = old_values.find do
        |old_value|
        old_value.idx == new_value.idx
      end
      if ! old_value
        values_2b_added << new_value.handle_value
      elsif old_value and
          old_value.type != new_value.type ||
          old_value.data != new_value.data ||
          old_value.ttl_type != new_value.ttl_type ||
          old_value.ttl != new_value.ttl ||
          old_value.refs.any? do
              |ref1|
              new_value.refs.none? do
                |ref2|
                ref1[:idx]    == ref2[:idx] &&
                ref1[:handle] == ref2[:handle]
              end # new_value.refs.any? do
            end || #old_value.refs.all? do
          new_value.refs.any? do
              |ref1|
              old_value.refs.none? do
                |ref2|
                ref1[:idx]    == ref2[:idx] &&
                ref1[:handle] == ref2[:handle]
              end # old_value.refs.any?
            end # new_value.refs.all? do
        values_2b_modified << new_value.handle_value
      end
    end
    old_values.each do
      |old_value|
      if new_values.none? { |new_value| new_value.idx == old_value.idx }
        values_2b_removed << old_value.idx
      end
    end
    requests = []
    if ! values_2b_added.empty?
      requests << HDLLIB::AddValueRequest.new(
        handle.to_java_bytes,
        values_2b_added.to_java( HDLLIB::HandleValue ),
        authentication_info( user_name )
      )
    end
    if ! values_2b_modified.empty?
      requests << HDLLIB::ModifyValueRequest.new(
        handle.to_java_bytes,
        values_2b_modified.to_java( HDLLIB::HandleValue ),
        authentication_info( user_name )
      )
    end
    if ! values_2b_removed.empty?
      requests << HDLLIB::RemoveValueRequest.new(
        handle.to_java_bytes,
        values_2b_removed.to_java( Java::int ),
        authentication_info( user_name )
      )
    end
    requests.each do
      |request|
      response = resolver.processRequest( request )
      if response.kind_of? HDLLIB::ErrorResponse
        case response.responseCode
        when HDLLIB::ErrorResponse::RC_INSUFFICIENT_PERMISSIONS
          raise ReST::HTTPStatus, 'FORBIDDEN'
        else
          raise response.to_string
        end
      end
    end
  end


=begin
Deletes a Handle
@param handle [#to_s]
@param user_name [#to_s]
@return [void]
@raise [ReST::HTTPStatus]
=end
  def delete_handle handle, user_name
    authInfo = authentication_info( user_name )
    request = HDLLIB::DeleteHandleRequest.new(
      handle.to_java_bytes,
      authInfo
    )
    response = resolver.processRequest( request )
    if response.kind_of? HDLLIB::ErrorResponse
      case response.responseCode
      when HDLLIB::ErrorResponse::RC_INSUFFICIENT_PERMISSIONS
        raise ReST::HTTPStatus, 'FORBIDDEN'
      when HDLLIB::ErrorResponse::RC_HANDLE_NOT_FOUND
        raise ReST::HTTPStatus, 'NOT_FOUND'
      else
        raise response.to_string
      end
    end
  end


end # class << self


end # module HS
end # module EPIC