require 'net/http'
require 'json'

module DorFetcher
  
  class Client
    
    @@supported_params = [:first_modified, :last_modified]
    @@count_only_param = "?rows=0"
    @@default_service_url = 'http://127.0.0.1:3000'
    @@counts_key = 'counts'
    
    #Create a new instance of DorFetcher::Client
    #@param options [Hash] Currently supports :service_url and :skip_heartbeat.
    #@param :service_url is the base url for API queries.  Defaults to http://127.0.0.1:3000
    #@param :skip_heartbeat will tell the init to skip querying the :service_url and seeing if the API is responsive
    #@example
    #    df = DorFetcher::Client.new({:service_url='http://SERVICEURL'})
    def initialize options = {}
      #TODO: Check for a well formed URL and a 200 from the destination before just accepting this
      @service_url = options[:service_url] || @@default_service_url

      if not options[:skip_heartbeat]
        raise "DorFetcher::Client Error! No response from #{@service_url}" if not self.is_alive
      end
    end
    
    #Check to see if the dor-fetcher-service is responding to requests, this is a basic heart beat checker
    #@return [Boolean] True for a service that responds, False for a service that does not.
    def is_alive
      resp = Net::HTTP.get_response(URI.parse(@service_url))
      #Since dor-fetcher-service uses the is_alive gem, the main page should simply have okay on it
      return "ok".eql?(resp.body) 
    end
    
    
    #Get a hash of all members of a collection and the collection itself
    #
    #@param collection [String] we expect pid/druid
    #@param params [Hash] we expect :count_only or any of @@supported_params
    #@return [Hash] Hash of all objects in the collection including 
    #pid/druid, title, date last modified, and count
    def get_collection(collection, params = {})
      return query_api('collections', collection, params)
    end
    
    #Get the count of the number of items in a collection, including the 
    #collection object itself
    #@param collection [String] we expect pid/druid
    #@param params [Hash] we expect :count_only or any of @@supported_params
    #@return [Integer] Number found
    def get_count_for_collection(collection, params = {})
      return query_api('collections', collection, add_count_only_param(params))
    end
  
    #Get a Hash of all the collections in the digital repository 
    #@return [Hash] Hash of all collections including pid/druid, title,  
    #date last modified, and count
    def list_all_collections
      return query_api('collections', '', {})
    end
    
    #Get a Count of all the collections in the digital repository 
    #@return [Integer] Number of all collections
    def total_collection_count
      return query_api('collections', '', {:count_only=>true})
    end
  
    #Get the APO and all objects governed by the APO
    #@param apo [String] pid/druid of the APO
    #@param params [Hash] we expect :count_only or any of @@supported_params
    #@return [Hash] Hash of all objects governed by the APO including    
    #pid/druid, title, date last modified, and count
    def get_apo(apo, params= {})
      return query_api('apos', apo, params)
    end
    
    #Get the count of the number of objects in an APO, including the 
    #APO object itself
    #@param apo [String] we expect pid/druid
    #@param params [Hash] we expect :count_only or any of @@supported_params
    #@return [Integer] Number found
    def get_count_for_apo(apo, params={})
      return query_api('apos', apo, add_count_only_param(params))
    end
  
    #Get a Hash of all the APOs in the digital repository 
    #@return [Hash] Hash of all APOs including pid/druid, title,  
    #date last modified, and count
    def list_all_apos
      return query_api('apos', '', {})
    end
    
    #Get a Count of all the APOs in the digital repository 
    #@return [Integer] Number of all APOs
    def total_apo_count
      return query_api('apos', '', {:count_only=>true})
    end
    
    #Method to parse full Hash into an array containing only the druids
    #
    #@param response [Hash] Hash as returned by query_api
    #@return [Array] the array listing all druids in the supplied Hash
    def druid_array(response)
      return_list = []
      j = response
      j.keys.each do |key|
        if key != @@counts_key
          j[key].each do |item|
            return_list << item['druid'] if item['druid'] != nil
          end
        end
      end
      return return_list
    end
    #Query a RESTful API and return the JSON result as a Hash
    #@param base [String] The name of controller of the Rails App you wish to
    #route to
    #@param druid [String] The druid/pid of the object you wish to query,
    #or empty string for no specific druid
    #@param params [Hash] we expect :count_only or any of @@supported_params
    #@return [Hash] Hash of all objects governed by the APO including    
    #pid/druid, title, date last modified, and count
    def query_api(base, druid, params)
      url = "#{@service_url}/#{base}/#{druid}#{add_params(params)}"
      
      begin
        resp = Net::HTTP.get_response(URI.parse(url))
      rescue
        raise "Connection Error with url #{url}"
      end
      
      return resp.body.to_i if params[:count_only] == true
      return JSON[resp.body] #Convert the response JSON to a Ruby Hash
    end
    
    #Transform a parameter hash into a RESTful API parameter format
    #
    #@param input_params [Hash] {The existing parameters, eg time and tag}
    #@return [String] parameters in the Hash now formatted into a RESTful parameter string
    def add_params(input_params)
      args_string = ""
      
      #Handle Count Only
      args_string << @@count_only_param if input_params[:count_only] == true
      
      #If we did not add in a rows=0 param, args_string will have a size of 
      #zero
      #If we did add in a rows=0 param, this will set count to greater than 
      #zero
      count = args_string.size
      @@supported_params.each do |p|
        operator = "?"
        operator = "&" if count > 0
        args_string << "#{operator}#{p.to_s}=#{input_params[p]}" if input_params[p] != nil
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
    
    #Get the Base URL this instance will run RESTful API calls against
    #@return [String] the url
    def service_url
      return @service_url
    end
    
  end
    
end


