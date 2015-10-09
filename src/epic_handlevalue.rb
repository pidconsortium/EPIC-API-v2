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

require 'epic_hs.rb'

module EPIC


# Wrapper around +net.handle.hdllib.HandleValue+.
#
# A Handle, represented in this software system by {Handle}, is a collection of
# Handle Values, represented by this class.
# @see Handle#values
class HandleValue # < Resource

  # Meta programming helper method.
  #
  # This private class method can be called inside the class definition of
  # {HandleValue}.
  # @example
  #   # Create a Ruby attribute "timestamp" which is mapped
  #   # to Java methods getTimestamp() and setTimestamp():
  #   map_java_bytes :timestamp, :Timestamp
  # @param ruby_name [Symbol] name of the Ruby attribute to create
  # @param java_name [Symbol] name of the corresponding attribute in
  #   +net.handle.hdllib.HandleValue+
  # @see map_java_bytes
  # @private
  def self.map_java ruby_name, java_name
    define_method ruby_name do
      @handle_value.send( :"get#{java_name}" )
    end
    define_method :"#{ruby_name}=" do
      |value|
      @handle_value.send( :"set#{java_name}", value )
      value
    end
  end


  # Meta programming helper method.
  #
  # {include:map_java}
  #
  # The difference between this method and {map_java} is that {map_java} works
  # for attributes with primitive Java types, while this method wraps a Ruby
  # {String} attribute around a Java attribute of type +byte[]+. In order to
  # do so, we need to define how the Java octet-stream must be interpreted,
  # i.e. which encoding to use.
  # @example
  #   # Create a Ruby attribute "data" which is mapped
  #   # to Java methods getData() and setData():
  #   map_java_bytes :data, :Data, Encoding::BINARY
  # @param (see map_java)
  # @param encoding [Encoding] The encoding to be used when interpreting the
  #   Java byte array.
  # @see map_java
  # @private
  def self.map_java_bytes ruby_name, java_name, encoding = Encoding::UTF_8
    define_method ruby_name do
      String.from_java_bytes(
        @handle_value.send( :"get#{java_name}" )
      ).force_encoding(encoding)
    end
    define_method :"#{ruby_name}=" do
      |value|
      @handle_value.send(
        :"set#{java_name}",
        value.force_encoding(Encoding::ASCII_8BIT).to_java_bytes
      )
      value
    end
  end


  # @!attribute [rw]
  # @return [String] the type of this handle value
  map_java_bytes :type, :Type
  # @!attribute [rw]
  # @return [String with Encoding::ASCII_8BIT] the binary data in this handle value
  map_java_bytes :data, :Data, Encoding::ASCII_8BIT
  # @!attribute [rw]
  # @return [Integer] the index of this handle value
  map_java :idx, :Index
  # @!attribute [rw]
  # @return [Integer] the time-to-live of this handle value
  map_java :ttl, :TTL
  # Type of attribute {#ttl}.
  # [0] *Relative* Interpret {#ttl} as the number of seconds a client or proxy
  #     may/should cache the result.
  # [1] *Absolute* Interpret {#ttl} as an absolute timestamp, expressed in
  #     seconds since epoch, until which this handle value is current.
  # @!attribute [rw] ttl_type
  # @return [0 or 1]
  map_java :ttl_type, :TTLType
  # The timestamp of the last modification of this handle value, in seconds
  # since epoch.
  # @!attribute [rw]
  # @return [Integer]
  map_java :timestamp, :Timestamp
  # Is the administrator allowed to read this handle value?
  # @!attribute [rw]
  # @return [Boolean]
  map_java :admin_read,  :AdminCanRead
  # Is the administrator allowed to overwrite this handle value?
  # @!attribute [rw]
  # @return [Boolean]
  map_java :admin_write, :AdminCanWrite
  # Is the world allowed to read this handle value?
  # @!attribute [rw]
  # @return [Boolean]
  map_java :pub_read,    :AnyoneCanRead
  # Is the world allowed to overwrite this handle value?
  # @!attribute [rw]
  # @return [Boolean]
  map_java :pub_write,   :AnyoneCanWrite


  # The Java Object wrapped by +self+.
  # @return [HDLLIB::HandleValue]
  attr_reader :handle_value


  # References in this handle value.
  # @!attribute [rw] refs
  # @return [ Array< Hash{ :idx => Integer, :handle => Integer } > ]
  def refs
    @handle_value.getReferences.to_a.collect do
      |ref|
      { :idx => ref.index, :handle => String.from_java_bytes( ref.handle ) }
    end
  end


  def refs= p_refs
    @handle_value.setReferences(
      p_refs.collect do
        |ref|
        HS::HDLLIB::ValueReference.new(
          ref[:handle].to_java_bytes,
          ref[:idx]
        )
      end.to_java HS::HDLLIB::ValueReference
    )
  end


  # @param dbrow [Hash] an optional hash of values to initialize this handle
  #   value with.
  # @see Handle#initialize
  def initialize dbrow = nil
    # super path
    # matches = %r{/([^/]+/[^/]+)/(\d+)\z}.match path
    # raise "Unexpected path: #{path}" unless matches
    # @handle = matches[1].to_path.unescape
    # @idx = matches[2].to_i
    @handle_value = HS::HDLLIB::HandleValue.new
    if dbrow
      self.idx       = dbrow[:idx].to_i
      self.type      = dbrow[:type].to_s
      self.data      = dbrow[:data].to_s
      self.ttl_type  = dbrow[:ttl_type].to_i
      self.ttl       = dbrow[:ttl].to_i
      self.timestamp = dbrow[:timestamp].to_i
      if dbrow[:refs]
        @handle_value.setReferences(
          dbrow[ :refs ].split("\t").collect do
            |ref|
            ref = ref.split ':', 2
            HS::HDLLIB::ValueReference.new(
              ref[1].to_java_bytes,
              ref[0].to_i
            )
          end.to_java HS::HDLLIB::ValueReference
        )
      end  
      self.admin_read  = dbrow[:admin_read]  && 0 != dbrow[:admin_read]
      self.admin_write = dbrow[:admin_write] && 0 != dbrow[:admin_write]
      self.pub_read    = dbrow[:pub_read]    && 0 != dbrow[:pub_read]
      self.pub_write   = dbrow[:pub_write]   && 0 != dbrow[:pub_write]
    else
      self.timestamp = Time.new.to_i
    end
  end


  # def self.refs2string refs
    # refs.collect do
      # |ref|
      # ref[:idx].to_s + ':' + ref[:handle]
    # end.join( "\t" )
  # end
#
#
  # def self.string2refs string
    # string.split("\t").collect do
      # |ref|
      # ref = ref.split ':', 2
      # {
        # :idx    => ref[0].to_i,
        # :handle => ref[1]
      # }
    # end
  # end


  # Accesses the data in this handle value, just like {#data}.
  # While {#data} accesses the raw octet-stream verbatim, this attribute
  # parses the raw bytes into structured data for certain known value types.
  #
  # For unknown value types, it returns a UTF-8 encoded string if the data can
  # be interpreted as such. If the binary data doesn't constitute a valid UTF-8
  # string, this attribute is +nil+.
  # @!attribute [rw] parsed_data
  # @return [Array, Hash, String, nil]
  # @todo check if the transcodings can also be done with {String#force_encoding}.
  def parsed_data
    nicetype = type.gsub( /\W+/, '_' )
    if HS.respond_to? :"unpack_#{nicetype}"
      HS.send :"unpack_#{nicetype}", self.data
    else
      begin
        retval = self.data.encode( Encoding::UTF_8, Encoding::UTF_8 )
        if %r{[\x00-\x08\x0B\x0C\x0E-\x1F]}.match(retval) ||
           self.data != retval.encode( Encoding::ASCII_8BIT, Encoding::ASCII_8BIT )
          nil
        else
          retval
        end
      rescue
        nil
      end
    end
  end


  def parsed_data= p_data
    nicetype = type.gsub( /\W+/, '_' )
    self.data =
    if HS.respond_to? :"pack_#{nicetype}"
      HS.send :"pack_#{nicetype}", p_data
    else
      p_data.to_s.encode( Encoding::ASCII_8BIT, Encoding::ASCII_8BIT )
    end
  end


end # class HandleValue


end # module EPIC
