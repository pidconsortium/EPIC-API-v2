require 'singleton'

module EPIC
  class CheckConfig

    include Singleton

    #    TODO:
    #    adding  Sanity check for institutes

    # Specifiy entities for checking and test methods
    # if the entity is a hash, specify keys as follow: "ENTITY,KEYNAME"
    #
    # Convention:
    # "ENTITY",KEY" => {check_method1,check_method2, ...}
    #
    @@entities = {
      "REALM" => "not_empty,is_string",
      "USERS" => "not_empty,is_hash",
      "OPAQUE"=> "not_empty,is_string",
      "SEQUEL_CONNECTION_ARGS" => "is_defined",
      "DEFAULT_GENERATOR" => "not_empty,is_string",
      "DEBUG_SETTINGS" => "not_empty,is_hash",
      "DEBUG_SETTINGS[:debug_base_path]" => "not_empty,is_string",
      "DEBUG_SETTINGS[:enabled]" => "is_bool",
      # TODO: ENFORCE_PROFILES
    }

    def initialize()
      perform_checks()
    end

    private

    def perform_checks()
      @@entities.each do |key_entity,value_checks|
        # Check if, key is present in config
        raise Exception.new( "CONFIG-CHECK: " + key_entity + " not found in config or users file!") if eval("EPIC::" + key_entity).nil?
        # Create an Array of Checks to be perfomed
        checks = value_checks.gsub(" ", "").split(",")
        # Perform checks
        checks.each do |check|
          # Check if check-method has beend defined in class
          method_found = false
          self.private_methods.each do |method|
            if method.to_s.upcase === check.to_s.upcase
              method_found = true
              break
            end
          end
          unless method_found
            raise Exception.new( "CONFIG-CHECK: Check-Method \"#{check}\" not found. Check checking-instructions")
          end

          # Run the Check
          #puts "" + check + "(EPIC::" + key_entity + ")"
          result = eval("" + check + "(EPIC::" + key_entity + ")")
          unless result
            raise Exception.new( "CONFIG-CHECK: Check \"#{check}\" for \"#{key_entity}\" failed. Check config and user file.")
          end

        end
      end
    end

    def is_bool(entity)
       !!entity == entity
    end
    
    def not_empty(entity)
      entity.size() > 0
    end

    def is_hash(entity)
      entity.class == Hash
    end

    def is_string(entity)
      entity.kind_of? String
    end

    def is_defined(entity)
      entity.nil? != nil
    end

    def is_positiv_int(entity)
      entity.is_a? Integer and entity > -1
    end

    def is_directory(entity)
      puts entity
      File.directory?(entity)
    end

  end
end
