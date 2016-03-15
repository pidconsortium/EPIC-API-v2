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

#require 'epic_monkeypatches.rb'

# Require all the resources served by this Resource Factory:
require 'epic_handle.rb'
require 'epic_handles.rb'
require 'epic_handlevalue.rb'
require 'epic_nas.rb'
require 'epic_directory.rb'
require 'epic_profile.rb'
require 'epic_generator.rb'
require 'epic_version.rb'
require 'epic_debugger.rb'
require '../config.rb'
require '../secrets/users.rb'
require 'singleton'

# @todo Documentation
module EPIC

  # Resource Factory for all our ReSTful resources.
  #
  # {Rackful::Server} requires a {Rackful::Server#resource_factory resource factory}. This
  # singleton class implements EPIC's resource factory.
  #
  # Like every Singleton in a multi-threaded environment, this class must be thread safe!
  # @todo Move this class to a separate file? Not needed quite yet...
  class ResourceFactory

    include Singleton

    def initialize()
      Debugger.instance.debug("EPIC API Server started.")
      Debugger.instance.debug("No profiles specified in Config. EPIC API will run with default behaviour.") unless defined?(ENFORCED_PROFILES)
    end

    # Can be called by tainted resources, to be removed from the cache.
    # @return [self]
    def uncache path
      Debugger.instance.debug("epic.rb:#{__LINE__}:uncache resource")
      resource_cache.delete path.to_s.unslashify
      self
    end

    # @param path [Rackful::Path] the URI-encoded path to the resource.
    # @return [Resource, nil]
    # @see Rackful::Server#resource_factory for details
    def [] path
      Debugger.instance.debug("epic.rb:#{__LINE__}:dispatching resource")
      path = path.to_path unless Rackful::Path == path.class
      path.unslashify!
      segments = path.segments
      cached = resource_cache[path]
      # Legal values for +cached+ are:
      # - nil: the resource is not in cache
      # - false: resource was requested earlier, without success
      # - Rackful::Resource
      unless cached.nil?
        # if +cached+ is +false+, we want to return +nil+.
        return cached || nil
      end
      n = segments.length
      resource_cache[path] =
      if 0 === n
        Debugger.instance.debug("epic.rb:#{__LINE__}:GET all available paths | GET")
        StaticCollection.new(
        '/', [
          'handles/',
          'profiles/',
          'generators/',
          'version'
          #~ 'batches/'
        ]
        )
      elsif 'handles' === segments[0]
        if 1 === n
          Debugger.instance.debug("epic.rb:#{__LINE__}:GET all prefixes in system | GET")
          NAs.new( path.slashify )
        elsif %r{\A\d+\z} === segments[1] or %r{\A21.\d+\z} === segments[1] or %r{\A21.T\d+\z} === segments[1]        
          if 2 === n
            Debugger.instance.debug("epic.rb:#{__LINE__}:GET a list of all handles for an prefix | GET")
            Handles.new( path.slashify )
          elsif 3 === n
            Debugger.instance.debug("epic.rb:#{__LINE__}:GET a specific handle | GET")
            Handle.new path
          end
        end
      elsif 'generators' === segments[0]
        if 1 === n
          Debugger.instance.debug("epic.rb:#{__LINE__}:GET a list of all available generators | GET")
          StaticCollection.new(path.slashify, Generator.generators.keys)
        elsif 2 === n
          Debugger.instance.debug("epic.rb:#{__LINE__}:GET description of a generator | GET")
          generator = Generator.generators[segments[1]]
          generator && generator.new( path )
        end
      elsif 'profiles' === segments[0]
        if 1 === n
          Debugger.instance.debug("epic.rb:#{__LINE__}:GET a list of all available profiles | GET")
          StaticCollection.new(path.slashify, Profile.profiles.keys)
        else
          Debugger.instance.debug("epic.rb:#{__LINE__}:GET description of a profile | GET")
          profile = Profile.profiles[segments[1]]
          profile && profile.new( path )
        end
      elsif 'version' === segments[0]
        if 1 === n
          Debugger.instance.debug("epic.rb:#{__LINE__}:GET version | GET")
          Version.new path
        end
      end
    end

    private

    # For performance, this {ResourceFactory} maintains a cache of
    # {EPIC::Resource Resources} it has produced earlier <em>within this same
    # request.</em>
    #
    # Valid Hash values are:
    # [{Resource}] A cached resource
    # [false] The resource has been requested earlier, but wasn't found.
    # [nil] The resource hasn't been requested yet.
    # @return [Hash< unslashified_path => resource_object >]
    def resource_cache
      Rackful::Request.current.env[:epic_resource_cache] ||= Hash.new
    end

  end # class ResourceFactory

end # module EPIC
