

class Eresponse

    attr_reader :json_pid
  
    def initialize response, resource
       set_pid(resource.prefix,resource.suffix)
       length = json_pid.bytesize()
       response.body = self
       response.status = 201
       response.length = length
       response['Content-Length']=length.to_s()
       response['Content-Type']="application/json"
       response["Location"] = resource.path.to_s()
       response.header.delete('Content-Location')
       response.headers.merge! resource.default_headers
    end
    

    def set_pid the_prefix, the_suffix
      @json_pid = "\n"+'{"epic-pid":"'+the_prefix+'/'+the_suffix+'"}'+"\n"
    end
      

    def each
       yield @json_pid
    end

end
