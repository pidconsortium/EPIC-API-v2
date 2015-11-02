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

require 'epic_resource.rb'


module EPIC


class Generator < Resource


  # @api private
  # @return [Hash{ String(prefix) => Hash{ String(name) => Generator } }]
  def Generator.generators
    @@generators ||= {}
  end


  # @api private
  # @return [Hash{ String(name) => Generator }]
  def Generator.[] name
    generators[name.to_s.downcase]
  end

  
  def Generator.inherited klass
    generators[klass.name.split('::').last.downcase] = klass
  end

  
  # @!method generate(request)
  #   @param [Rackful::Request] request

  # @!method generate(request)
  #   @param [Rackful::Request] request
  class JUUID < Generator

    def to_rackful
      {
        'Description' => 'This generator uses JUUIDs to guarantee the uniqueness of created Handles.',
        'Query parameters' => {
          :prefix => 'Optional: a string of UTF-8 encoded printable unicode characters to put before the UUID.',
          :suffix => 'Optional: a string of UTF-8 encoded printable unicode characters to put after the UUID.'
        },
      }
    end

    def generate request

      prefix = request.GET['prefix'] || ''
      suffix = request.GET['suffix'] || ''
      prefix + java.util.UUID.randomUUID.to_s() + suffix
    end

  end # class JUUID < Generator

  # @!method generate(request)
  #   @param [Rackful::Request] request

  class GWDGJUUID < Generator

    def to_rackful
      {
        'Description' => 'This generator uses JUUIDs to guarantee the uniqueness of created Handles.',
        'Query parameters' => {
          :prefix => 'Optional: a string of UTF-8 encoded printable unicode characters to put before the UUID.',
          :suffix => 'Optional: a string of UTF-8 encoded printable unicode characters to put after the UUID.'
        },
      }
    end

    def generate request

      unless USERS[request.env['REMOTE_USER']][:institute]
        raise Rackful::HTTP403Forbidden, "No institute code is configured for your user."
      end

      prefix = request.GET['prefix'] || ''
      suffix = request.GET['suffix'] || ''
      prefix + java.util.UUID.randomUUID.to_s() + suffix
    end

  end # class GWDGJUUID < Generator




  # A generator that uses UUIDs to guarantee the uniqueness of created Handles.
  class UUID < Generator

    def to_rackful
      {
        'Description' => 'This generator uses UUIDs to guarantee the uniqueness of created Handles.',
        'Query parameters' => {
          :prefix => 'Optional: a string of UTF-8 encoded printable unicode characters to put before the UUID.',
          :suffix => 'Optional: a string of UTF-8 encoded printable unicode characters to put after the UUID.'
        },
      }
    end

    def generate request
      prefix = request.GET['prefix'] || ''
      suffix = request.GET['suffix'] || ''
      prefix + DB.instance.uuid + suffix
    end

  end # class UUID < Generator


  # A generator that creates GWDG-like strings to guarantee the uniqueness of created Handles.
  class GWDGPID < Generator

    def to_rackful
      {
        'Description' => 'This generator creates GWDG-like PID strings. A GWDG-like PID has the following syntax: namespace/[userprefix-]num1-num2-num3-C[-usersuffix] . More information on the structure: http://www.pidconsortium.eu/index.php?page=structure',    #and guarantees the uniqueness of created Handles.', # (by using DB sequence).'
        'Query parameters' => {
          # Institute code is not a user input anymore
          ### :inst => 'Mandatory: Institutecode, a string of UTF-8 encoded printable unicode characters to put at the beginning of the GWDGPID.',
          :prefix => 'Optional: a string of UTF-8 encoded printable unicode characters to put before the GWDGPID.',
          :suffix => 'Optional: a string of UTF-8 encoded printable unicode characters to put after the GWDGPID.'
        }
      }
    end


    # @todo Parameter `prefix` should be a hex string? How long may it be?
    # @todo Parameter `suffix` should be a hex string? How long may it be?
    # @todo Sequences: Do we want own sequence numbers per institute like
    #       `DB.instance.gwdgpidsequence('inst')`?
    # @todo: multi-institute user: the user input can be a hint, but has to be proven.
    def generate request
    
      # Institute code is provided by the service and not as user input!
      ### unless request.GET['inst']
      ###   raise Rackful::HTTP400BadRequest, 'No institute code is provided in the request.'
      ### end # unless
      unless USERS[request.env['REMOTE_USER']][:institute]
        raise Rackful::HTTP403Forbidden, "No institute code is configured for your user."
      end

      ###    raise HTTP403Forbidden, "The operation is not allowed for the institute code." \
      ###   unless (USERS[request.env['REMOTE_USER']][:institute].upcase != request.GET['inst'].upcase)
        inst = USERS[request.env['REMOTE_USER']][:institute].upcase        # institute from users file
      ###    unless inst.length != 4
      ###      raise HTTP400BadRequest, 'Invalid institute code is provided in the request.'
      ###    end
  
      prefix = ( request.GET['prefix'] ) ? request.GET['prefix'].upcase + '-' : ''
      suffix = ( request.GET['suffix'] ) ? '-' + request.GET['suffix'].upcase : ''
      sequence = DB.instance.gwdgpidsequence
      ### sequence = 323984    #323984->4F190 (9),  #20249->004F19 (E),  #312607->"04C51F" (D),  #304415->"04A51F" (1),  #5551->"015AF" (5)
      if sequence < 1 or sequence > "FFFFFFFFFFFF".to_i(16)
        raise Rackful::HTTP500InternalServerError, "A new sequence number cannot be generated."
      end

      # Fixnum -> Hex: http://www.ruby-doc.org/core/classes/Fixnum.html#M001069
      # Fixnum.to_s(base=16): Returns a string containing the representation of fix radix base (between 2 and 36).
      sequence = sequence.to_s(16).upcase.rjust(12,'0')

      # Luhn mod N with alphabet 0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F (so it is 'Luhn mod 16')
      checksum = luhnModNCheckDigit(sequence, 16)
      ### debug checksum.inspect

      prefix + sequence[0..3] + '-' + sequence[4..7] + '-' + sequence[8..11] + '-' + checksum + suffix
    end

    # Checksum digit generation using the Luhn mod N algorithm
    # @param number [String]
    # @param base [String]
    # @return digit [String]
    def luhnModNCheckDigit number, base
    ### The Luhn mod N algorithm is an extension to the Luhn algorithm (which is also known as Luhn mod 10 algorithm).
    ### Luhn mod N allows sequences of non-numeric characters.
    ### More info: http://en.wikipedia.org/wiki/Luhn_mod_N_algorithm
    
    ###debug number.inspect
    parity = number.length % 2    ### n % 2 == 0 means even

    sum = 0
    number.split('').each_with_index do |c, i|
            ### Hex->Dec: Fixnum.to_s(base=10) returns a string containing the representation of fix radix base (between 2 and 36).
        ###digit = ((c.to_i).to_s(10)).to_i
        ### The integer ordinal of a one-character string is required to be compatible with Ruby 1.8 and 1.9
        digit = c.gsub(/[A-F]/) { |p| (p.respond_to?(:ord) ? p.ord : p[0]) - 55 }    # A->10, B->11, ..., F->15
        digit = digit.to_i    # String -> Fixnum
        ###debug "#{i}. digit: #{digit}
#        digit = (digit * 2) % 10 if i % 2 == parity
        digit = (digit * 2) if i % 2 == parity    # i % 2 == 0 means even
        ###debug "#{i}. digit (after double): #{digit}
        ### reduce 2-digit number into single-digit number: ex. x1E=>x1+xE=xF (d16 => d1 + d6 = d7)
        ### 3 ways: either 1+digit%10 or just simply digit-9 or (digit/base)+(digit%base)
#        digit = (digit / base) + (digit % base) if digit != 0    # reduce digits and sum the digits as expressed in base N
        digit = 1 + (digit % base) if digit.to_i >= base    # reduce digits and sum the digits as expressed in base N
        ###debug "#{i}. digit (reduced): #{digit}
        sum += digit
    end

    ### calculate the number that must be added to the "sum" to make it divisible by "N"
    code = (base - sum.modulo(base) -1 )
        ###debug "code (): #{code}
    return (code <= 9) ? code.to_s : (code + 55).chr    # Dec->Hex: 0->0, .., 9->9, 10->A, 11->B, .., 16->F
    end

  end # class GWDGPID < Generator


  # A generator that creates GWDG-like strings to guarantee the uniqueness of created Handles.
  class GWDGOLDPID < Generator

    def to_rackful
      {
        'Description' => 'Currently outdated, use the "gwdgpid" generator instead! This generator creates GWDG-like PID strings. A GWDG-like PID has the following syntax: PREFIX/00-XXXX-0000-0000-0000-C (prfix/fg-inst-num1-num2-num3-c). More information on the structure: http://www.pidconsortium.eu/index.php?page=structure',    #and guarantees the uniqueness of created Handles.', # (by using DB sequence).'
        'Query parameters' => {
          ### Institute code is not a user input anymore
          ###:inst => 'Mandatory: Institutecode, a string of UTF-8 encoded printable unicode characters to put at the beginning of the GWDGPID.',
          ###:prefix => 'Optional: a string of UTF-8 encoded printable unicode characters to put before the GWDGPID.',
          :suffix => 'Optional: a string of UTF-8 encoded printable unicode characters to put after the GWDGPID.'
        }
      }
    end


    # @todo Parameter `prefix` should be a hex string? How long may it be?
    # @todo Parameter `suffix` should be a hex string? How long may it be?
    # @todo Sequences: Do we want own sequence numbers per institute like
    #       `DB.instance.gwdgpidsequence('inst')`?
    def generate request
    
      # Institute code is provided by the service and not as user input!
      # @todo multi-institute user: the user input can be a hint, but has to be proven.
      unless USERS[request.env['REMOTE_USER']][:institute]
        raise HTTP403Forbidden, "No institute code is configured for your user."
      end

      inst = USERS[request.env['REMOTE_USER']][:institute].upcase        # institute from users file
      unless inst.length != 4
        raise HTTP400BadRequest, 'Invalid institute code is provided in the request.'
      end
  
      prefix = ( request.GET['prefix'] ) ? request.GET['prefix'].upcase + '-' : ''
      suffix = ( request.GET['suffix'] ) ? '-' + request.GET['suffix'].upcase : ''
      sequence = DB.instance.gwdgpidsequence
      #sequence = 323984    #323984->4F190 (9),  #20249->004F19 (E),  #312607->"04C51F" (D),  #304415->"04A51F" (1),  #5551->"015AF" (5)
      if sequence < 1 or sequence > "FFFFFFFFFFFF".to_i(16)
        raise HTTP500InternalServerError, "A new sequence number cannot be generated."
      end

      # Fixnum -> Hex: http://www.ruby-doc.org/core/classes/Fixnum.html#M001069
      # Fixnum.to_s(base=16): Returns a string containing the representation of fix radix base (between 2 and 36).
      sequence = sequence.to_s(16).upcase.rjust(12,'0')

      # Luhn mod N with alphabet 0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F (so it is 'Luhn mod 16')
      checksum = luhnModNCheckDigit(sequence, 16)
      #debug checksum.inspect

      '00-' + inst + '-' + prefix + sequence + '-' + checksum + suffix
    end

    # Checksum digit generation using the Luhn mod N algorithm
    # @param number [String]
    # @param base [String]
    # @return digit [String]
    def luhnModNCheckDigit number, base
      # The Luhn mod N algorithm is an extension to the Luhn algorithm (which is also known as Luhn mod 10 algorithm).
      # Luhn mod N allows sequences of non-numeric characters.
      # More info: http://en.wikipedia.org/wiki/Luhn_mod_N_algorithm
    
      #debug number.inspect
      parity = number.length % 2 # n % 2 == 0 means even

      sum = 0
      number.split('').each_with_index do |c, i|
        ### Hex->Dec: Fixnum.to_s(base=10) returns a string containing the representation of fix radix base (between 2 and 36).
        ###digit = ((c.to_i).to_s(10)).to_i
        ### The integer ordinal of a one-character string is required to be compatible with Ruby 1.8 and 1.9
        digit = c.gsub(/[A-F]/) { |p| (p.respond_to?(:ord) ? p.ord : p[0]) - 55 }    # A->10, B->11, ..., F->15
        digit = digit.to_i    # String -> Fixnum
        ###debug "#{i}. digit: #{digit}
        #        digit = (digit * 2) % 10 if i % 2 == parity
        digit = (digit * 2) if i % 2 == parity    # i % 2 == 0 means even
        ###debug "#{i}. digit (after double): #{digit}
        ### reduce 2-digit number into single-digit number: ex. x1E=>x1+xE=xF (d16 => d1 + d6 = d7)
        ### 3 ways: either 1+digit%10 or just simply digit-9 or (digit/base)+(digit%base)
        #        digit = (digit / base) + (digit % base) if digit != 0    # reduce digits and sum the digits as expressed in base N
        digit = 1 + (digit % base) if digit.to_i >= base    # reduce digits and sum the digits as expressed in base N
        ###debug "#{i}. digit (reduced): #{digit}
        sum += digit
      end

      ### calculate the number that must be added to the "sum" to make it divisible by "N"
      code = (base - sum.modulo(base))
      #debug "code (): #{code}
      return (code <= 9) ? code.to_s : (code + 55).chr    # Dec->Hex: 0->0, .., 9->9, 10->A, 11->B, .., 16->F
    end

  end # class GWDGOLDPID < Generator

end # class Generator

end # module EPIC

