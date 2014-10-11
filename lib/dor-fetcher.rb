require 'net/http'

class DorFetcher
    
    #TODO:  Make this load via a config file
    @@fetcher_service_url = 'http://127.0.0.1:3000'
    @@supported_params = [:first_modified, :last_modified]
    @@count_only_param = "?rows=0"
    
    #options :count_only, :first_modified, :last_modified
    def self.get_collection(collection, params = {})
      return query_api('collection', collection, params)
    end
    
    def self.get_count_for_collection(collection, params = {})
      return query_api('collection', collection, add_count_only_param(params))
    end
  
    def self.list_all_collections
      return query_api('collection', '', {})
    end
    
    def self.total_collection_count
      return query_api('collection', '', {:count_only=>true})
    end
  
    #options :count_only, :first_modified, :last_modified
    def self.get_apo(apo, params= {})
      return query_api('apo', apo, params)
    end
    
    def self.get_count_for_apo(apo, params={})
      return query_api('apo', apo, add_count_only_param(params))
    end
  
    def self.list_all_apos
      return query_api('apo', '', {})
    end
    
    def self.total_apo_count
      return query_api('apo', '', {:count_only=>true})
    end
    
    
    def self.query_api(base_url, druid, params)
      url = "#{@@fetcher_service_url}/#{base_url}/#{druid}#{add_params(params)}"
      begin
        resp = Net::HTTP.get_response(URI.parse(url))
      rescue
        raise 'Connection Error' 
      end
      
      return resp.body.to_i if params[:count_only] == true
      return resp.body
      
    end
    
    def self.add_params(params)
      args_string = ""
      
      #Handle Count Only
      args_string << @@count_only_param if params[:count_only] == true
      
      @@supported_params.each do |p|
        args_string << "#?{p.to_s}=#{params[p]}" if params[p] != nil
      end
      return args_string
    end
    
    def self.add_count_only_param(params)
      params.store(:count_only, true)
      return params
    end
    
end


