require 'net/http'

module DorFetcher
  
  class Client
    
    @@supported_params = [:first_modified, :last_modified]
    @@count_only_param = "?rows=0"
    
    
    def initialize(service_url)
      #TODO: Check for a well formed URL and a 200 from the destination before just accepting this
      @service_url = service_url
    end
    #options :count_only, :first_modified, :last_modified
    def get_collection(collection, params = {})
      return query_api('collection', collection, params)
    end
    
    def get_count_for_collection(collection, params = {})
      return query_api('collection', collection, add_count_only_param(params))
    end
  
    def list_all_collections
      return query_api('collection', '', {})
    end
    
    def total_collection_count
      return query_api('collection', '', {:count_only=>true})
    end
  
    #options :count_only, :first_modified, :last_modified
    def get_apo(apo, params= {})
      return query_api('apo', apo, params)
    end
    
    def get_count_for_apo(apo, params={})
      return query_api('apo', apo, add_count_only_param(params))
    end
  
    def list_all_apos
      return query_api('apo', '', {})
    end
    
    def total_apo_count
      return query_api('apo', '', {:count_only=>true})
    end
    
    
    def query_api(base, druid, params)
      url = "#{@service_url}/#{base}/#{druid}#{add_params(params)}"
      begin
        resp = Net::HTTP.get_response(URI.parse(url))
      rescue
        raise 'Connection Error with url #{url}' 
      end
      
      return resp.body.to_i if params[:count_only] == true
      return resp.body
      
    end
    
    def add_params(params)
      args_string = ""
      
      #Handle Count Only
      args_string << @@count_only_param if params[:count_only] == true
      
      @@supported_params.each do |p|
        args_string << "#?{p.to_s}=#{params[p]}" if params[p] != nil
      end
      return args_string
    end
    
    def add_count_only_param(params)
      params.store(:count_only, true)
      return params
    end
  end
    
end


