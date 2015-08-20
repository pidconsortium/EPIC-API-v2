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

#~ require 'rubygems'
require 'sequel'
require 'singleton'

module EPIC


# @todo multi-host sites
class DB


  include Singleton


  DEFAULT_LIMIT = 1000


  def pool
    LOGGER.debug_method(self, caller)
    @pool[self.sql_depth] ||= Sequel.connect(*SEQUEL_CONNECTION_ARGS)
  end


  def sql_depth
    LOGGER.debug_method(self, caller)
    Thread.current[:epic_sql_depth] ||= 0
  end


  def sql_depth= n
    LOGGER.debug_method(self, caller, n)
    Thread.current[:epic_sql_depth] = n.to_i
  end


  def initialize
    @all_nas = nil
    @pool = []
  end


  def all_nas
    @all_nas ||= self.pool[:nas].select(:na).collect { |row| row[:na] }
  end


  def each_handle( prefix = nil, limit = DEFAULT_LIMIT, page = 1 )
    LOGGER.debug_method(self, caller, [prefix, limit, page])
    if (page = page.to_i) < 1
      raise "parameter page must be greater than 0."
    end
    if (limit = limit.to_i) < 0
      raise "parameter limit must be greater than or equal to 0."
    end
    ds = self.pool[:handles].select(:handle).distinct
    if prefix
      ds = ds.filter( 'handle LIKE ?', prefix.to_s + '/%' )
    end
    if 0 < limit
      ds = ds.limit( limit, (page - 1) * limit )
    end
    self.sql_depth = self.sql_depth + 1
    begin
      ds.each { |row| yield row[:handle] }
    ensure
      self.sql_depth = self.sql_depth - 1
    end
  end


  def each_handle_filtered( prefix, filter, limit = DEFAULT_LIMIT, page = 1 )
    LOGGER.debug_method(self, caller, [prefix, filter, limit, page])
    if (page = page.to_i) < 1
      raise "parameter page must be greater than 0."
    end
    if (limit = limit.to_i) < 0
      raise "parameter limit must be greater than or equal to 0."
    end
    ds = nil
    filter.each do
      | type, value |
      value = value.
        gsub( /([%\\_])/, "\\\\\\1" ).
        gsub( /([^~]|\A)\*/, "\\1%" ).
        gsub( /~(.)/, "\\1" )
      tmp_ds = self.pool[:handles].
        select(:handle).
        distinct
      if 'handle' === type
        tmp_ds = tmp_ds.filter( 'handle LIKE ?', prefix.to_s + '/' + value )
      else
      	tmp_ds = tmp_ds.
          filter( 'handle LIKE ?', prefix.to_s + '/%' ).
          filter( 'type = ?', type ).
          filter( 'data LIKE ?', value )
      end
      ds = ds ? ds.where( :handle => tmp_ds ) : tmp_ds
    end
    if 0 < limit
      ds = ds.limit( limit, (page - 1) * limit )
    end
    self.sql_depth = self.sql_depth + 1
    begin
      ds.each { |row| yield row[:handle] }
    ensure
      self.sql_depth = self.sql_depth - 1
    end
  end


  def all_handle_values handle
    LOGGER.debug_method(self, caller, handle)
    begin
      myquery = self.pool[:handles].where( :handle => handle )
      ds = myquery.all
    rescue
      msg = "APPLICATION STOPPED: Cannot connect to database!"
      LOGGER.fatal(msg)
      abort(msg)
    end  
    
  end


  def uuid
    returnvalue = self.pool['SELECT UUID()'].get
      LOGGER.debug("Extracting UUID: #{returnvalue} from database")
    returnvalue
  end


  # @return [Fixnum]
  def gwdgpidsequence
    ### INSERT INTO `pidsequence` (`processID`) VALUE (NULL);
    ### SELECT LAST_INSERT_ID()
    ### SELECT AUTO_INCREMENT FROM information_schema.tables WHERE table_name = 'pidsequence';
    ###self.pool['INSERT INTO pidsequence (processID) VALUE (NULL); SELECT LAST_INSERT_ID()'].get
    ###self.pool['SELECT AUTO_INCREMENT FROM information_schema.tables WHERE table_name = "pidsequence"].get
    self.pool["INSERT INTO pidsequence (processID) VALUES (NULL)"].insert
  end


end


end
