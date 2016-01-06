require 'rest_client'
require 'json'
require 'addressable/uri'

module DorFetcher

  class Client

    @@supported_params = [:first_modified, :last_modified, :count_only, :status]
    @@count_only_param = 'rows=0'
    @@default_service_url = 'http://127.0.0.1:3000'
    @@counts_key = 'counts'

    # Create a new instance of DorFetcher::Client
    # @param options [Hash] Currently supports :service_url and :skip_heartbeat.
    # @param :service_url is the base url for API queries.  Defaults to http://127.0.0.1:3000
    # @param :skip_heartbeat will tell the init to skip querying the :service_url and seeing if the API is responsive
    # @example
    #    df = DorFetcher::Client.new({:service_url='http://SERVICEURL'})
    def initialize(options = {})
      # TODO: Check for a well formed URL and a 200 from the destination before just accepting this
      @service_url = options[:service_url] || @@default_service_url
      @site = RestClient::Resource.new(@service_url)

      unless options[:skip_heartbeat]
        raise "DorFetcher::Client Error! No response from #{@service_url}" unless self.is_alive?
      end
    end

    # Return service info (rails env, version deployed, last restart and last deploy)
    # @return [hash] Hash containing service info
    def service_info
      resp = @site['about/version.json'].get
      JSON[resp]
    end

    # Check to see if the dor-fetcher-service is responding to requests, this is a basic heart beat checker
    # @return [Boolean] True for a service that responds, False for a service that does not.
    def is_alive?
      resp = @site.get
      200.eql?(resp.code) && 'ok'.eql?(resp)
    end


    # Get a hash of all members of a collection and the collection itself
    #
    # @param collection [String] we expect pid/druid
    # @param params [Hash] we expect :count_only or any of @@supported_params
    # @return [Hash] Hash of all objects in the collection including
    # pid/druid, title, date last modified, and count
    def get_collection(collection, params = {})
      query_api('collections', collection, params)
    end

    # Get the count of the number of items in a collection, including the
    # collection object itself
    # @param collection [String] we expect pid/druid
    # @param params [Hash] we expect :count_only or any of @@supported_params
    # @return [Integer] Number found
    def get_count_for_collection(collection, params = {})
      query_api('collections', collection, add_count_only_param(params))
    end

    # Get a Hash of all the collections in the digital repository that are accessioned
    # @return [Hash] Hash of all collections including pid/druid, title,
    # date last modified, and count
    def list_all_collections
      query_api('collections', '', {})
    end

    # Get a Hash of all the collections in the digital repository
    # @return [Hash] Hash of all collections including pid/druid, title,
    # date last modified, and count
    def list_registered_collections
      query_api('collections', '', {:status => 'registered'})
    end

    # Get a Count of all the collections in the digital repository
    # @return [Integer] Number of all collections
    def total_collection_count
      query_api('collections', '', {:count_only => true})
    end

    # Get the APO and all objects governed by the APO
    # @param apo [String] pid/druid of the APO
    # @param params [Hash] we expect :count_only or any of @@supported_params
    # @return [Hash] Hash of all objects governed by the APO including
    # pid/druid, title, date last modified, and count
    def get_apo(apo, params = {})
      query_api('apos', apo, params)
    end

    # Get the count of the number of objects in an APO, including the
    # APO object itself
    # @param apo [String] we expect pid/druid
    # @param params [Hash] we expect :count_only or any of @@supported_params
    # @return [Integer] Number found
    def get_count_for_apo(apo, params = {})
      query_api('apos', apo, add_count_only_param(params))
    end

    # Get a Hash of all the APOs in the digital repository that are accessioned
    # @return [Hash] Hash of all APOs including pid/druid, title,
    # date last modified, and count
    def list_all_apos
      query_api('apos', '', {})
    end

    # Get a Hash of all the APOs in the digital repository that are registered
    # @return [Hash] Hash of all APOs including pid/druid, title,
    # date last modified, and count
    def list_registered_apos
      query_api('apos', '', {:status => 'registereed'})
    end

    # Get a Count of all the APOs in the digital repository
    # @return [Integer] Number of all APOs
    def total_apo_count
      query_api('apos', '', {:count_only => true})
    end

    # Method to parse full Hash into an array containing only the druids
    #
    # @param response [Hash] Hash as returned by query_api
    # @param no_prefix [boolean] if true (default), remove the druid: prefix on all druids, if false, leave alone
    # @return [Array] the array listing all druids in the supplied Hash
    def druid_array(response, params = {})
      return_list = []
      j = response
      j.keys.each do |key|
        if key != @@counts_key
          j[key].each do |item|
            unless item['druid'].nil?
              druid = item['druid'].downcase
              druid.gsub!('druid:', '') if params[:no_prefix]
              return_list << druid
            end
          end
        end
      end
      return_list
    end
    # Query a RESTful API and return the JSON result as a Hash
    # @param base [String] The name of controller of the Rails App you wish to
    # route to
    # @param druid [String] The druid/pid of the object you wish to query,
    # or empty string for no specific druid
    # @param params [Hash] we expect :count_only or any of @@supported_params
    # @return [Hash] Hash of all objects governed by the APO including
    # pid/druid, title, date last modified, and count
    def query_api(base, druid, params)
      url = "#{@site}/#{base}"
      url += "/#{druid}" unless druid.nil? || druid.empty?
      url += "#{add_params(params)}" unless params.nil? || params.empty?
      begin
        # We need to use this method here for the longer timeout option
        resp = RestClient::Request.execute(:method => :get, :url => url, :timeout => 90000000, :open_timeout => 90000000)
      rescue
        raise "Connection Error with url #{url}"
      end

      # RestClient monkey patches its response so it looks like a string, but really isn't.
      # If you just dd resp.to_i, you'll get the HTML Code, normally 200, not the actually body text you want
      return resp[0..resp.size].to_i if params[:count_only] == true

      JSON[resp] # Convert the response JSON to a Ruby Hash
    end

  # Transform a parameter hash into a RESTful API parameter format
   #
   # @param input_params [Hash] {The existing parameters, eg time and tag}
   # @return [String] parameters in the Hash now formatted into a RESTful parameter string
   def add_params(input_params)
     input_params.delete_if {|key, value| !@@supported_params.include?(key)}
     uri = Addressable::URI.new
     uri.query_values = input_params
     qs = uri.query.gsub('count_only=true', @@count_only_param)
     "?#{qs}"
   end

    # Add the parameter so query_api knows only to get a count of the documents in solr
    #
    # @param params [Hash] {The existing parameters, eg time and tag}
    # @return [Hash] the params Hash plus the key/value set :count_only=>true
    def add_count_only_param(params)
      params.store(:count_only, true)
      params
    end

    # Get the Base URL this instance will run RESTful API calls against
    # @return [String] the url
    def service_url
      @service_url
    end

  end

end
