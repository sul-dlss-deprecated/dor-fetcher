require 'net/http'
require 'json'

module DorFetcher
  
  class Client
    
    @@supported_params = [:first_modified, :last_modified]
    @@count_only_param = "?rows=0"
    @@default_service_url = 'http://127.0.0.1:3000'
    
    #Call me with {:service_url='http://SERVICEURL'}
    def initialize options = {}
      #TODO: Check for a well formed URL and a 200 from the destination before just accepting this
      @service_url = options[:service_url] || @@default_service_url
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
    
    #Method to parse full Hash into an array containing only the druids
    #
    #@param response [Hash] Hash as returned by query_api
    #@return [Array] the array listing all druids in the supplied Hash
    def druid_array(response)
      return_list = []
      j = response
      j.keys.each do |key|
        j[key].each do |item|
          return_list << item['druid'] if item['druid'] != nil
        end
      end
      return return_list
    end
    
    def query_api(base, druid, params)
      url = "#{@service_url}/#{base}/#{druid}#{add_params(params)}"
      
      begin
        resp = Net::HTTP.get_response(URI.parse(url))
      rescue
        raise "Connection Error with url #{url}"
      end
      
      return resp.body.to_i if params[:count_only] == true
      return JSON[resp.body]
      
    end
    
    def add_params(params)
      args_string = ""
      
      #Handle Count Only
      args_string << @@count_only_param if params[:count_only] == true
      
      count = 0
      @@supported_params.each do |p|
        args_string << "?" if count == 0
        args_string << "&" if count > 0
        args_string << "#{p.to_s}=#{params[p]}" if params[p] != nil
        count += 1
      end
      return args_string
    end
    
    #Add the parameter so query_api knows only to get a count of the documents in solr
    #
    #@param params [Hash] {The existing parameters, eg time and tag}
    #@return [Hash] the params Hash plus the key/value set :count_only=>true
    def add_count_only_param(params)
      params.store(:count_only, true)
      return params
    end
    
    def service_url
      return @service_url
    end
    
  end
    
end


