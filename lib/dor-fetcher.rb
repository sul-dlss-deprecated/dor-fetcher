require 'rest_client'
require 'json'
require 'addressable/uri'

module DorFetcher
  class Client
    @@supported_params = [:first_modified, :last_modified, :count_only, :status]
    @@count_only_param = 'rows=0'
    @@default_service_url = 'http://127.0.0.1:3000'
    @@counts_key = 'counts'

    attr_reader :service_url # Base URL this instance will run RESTful API calls against

    # Create a new instance of DorFetcher::Client
    # @param options [Hash]
    # @option options [String] :service_url base url for API queries.  Default: http://127.0.0.1:3000
    # @option options [Boolean] :skip_heartbeat skip querying :service_url to confirm API is responsive.  Default: false
    # @example
    #    df = DorFetcher::Client.new(:service_url => 'http://SERVICEURL')
    def initialize(options = {})
      # TODO: Check for a well formed URL and a 200 from the destination before just accepting this
      @service_url = options[:service_url] || @@default_service_url
      @site = RestClient::Resource.new(@service_url)
      raise "DorFetcher::Client Error! No response from #{@service_url}" unless options[:skip_heartbeat] || is_alive?
    end

    # Return service info (rails env, version deployed, last restart and last deploy)
    # @return [hash] Hash containing service info
    def service_info
      resp = @site['about/version.json'].get
      JSON[resp]
    end

    # Check to see if the dor-fetcher-service is responding to requests, this is a basic heartbeat checker
    # @return [Boolean] True for a service that responds, False for a service that does not.
    def is_alive?
      resp = @site.get
      200.eql?(resp.code) && 'ok'.eql?(resp)
    end

    # Get a hash of all members of a collection and the collection itself
    #
    # @param collection [String] we expect pid/druid
    # @param params [Hash] we expect :count_only or any of @@supported_params
    # @return [Hash] Hash of all objects in the collection including: pid/druid, title, date last modified, and count
    def get_collection(collection, params = {})
      query_api('collections', collection, params)
    end

    # Get the count of the number of items in a collection, including the collection object itself
    # @param collection [String] we expect pid/druid
    # @param params [Hash] any of @@supported_params
    # @return [Integer] Number found
    def get_count_for_collection(collection, params = {})
      query_api('collections', collection, params.merge!(:count_only => true))
    end

    # Get a Hash of all the collections in the digital repository that are accessioned
    # @return [Hash] All collections including: pid/druid, title, date last modified, and count
    def list_all_collections
      query_api('collections', '', {})
    end

    # Get a Hash of all the collections in the digital repository
    # @return [Hash] All registered collections including: pid/druid, title, date last modified, and count
    def list_registered_collections
      query_api('collections', '', :status => 'registered')
    end

    # Get a Count of all the collections in the digital repository
    # @return [Integer] Number of all collections
    def total_collection_count
      query_api('collections', '', :count_only => true)
    end

    # Get the APO and all objects governed by the APO
    # @param apo [String] pid/druid of the APO
    # @param params [Hash] we expect :count_only or any of @@supported_params
    # @return [Hash] All objects governed by the APO including: pid/druid, title, date last modified, and count
    def get_apo(apo, params = {})
      query_api('apos', apo, params)
    end

    # Get the count of the number of objects in an APO, including the
    # APO object itself
    # @param apo [String] we expect pid/druid
    # @param params [Hash] we expect :count_only or any of @@supported_params
    # @return [Integer] Number found
    def get_count_for_apo(apo, params = {})
      query_api('apos', apo, params.merge!(:count_only => true))
    end

    # Get a Hash of all the APOs in the digital repository that are accessioned
    # @return [Hash] All APOs including: pid/druid, title, date last modified, and count
    def list_all_apos
      query_api('apos', '', {})
    end

    # Get a Hash of all the APOs in the digital repository that are registered
    # @return [Hash] All registered APOs including: pid/druid, title, date last modified, and count
    def list_registered_apos
      query_api('apos', '', :status => 'registered')
    end

    # Get a Count of all the APOs in the digital repository
    # @return [Integer] Number of all APOs
    def total_apo_count
      query_api('apos', '', :count_only => true)
    end

    # Parses full Hash into an array containing only the druids
    # @param response [Hash] Hash as returned by query_api
    # @param params [Hash{Symbol=>Boolean}] options
    # @option params [Boolean] :no_prefix if true (default), remove the 'druid:' prefix on all druids
    # @return [Array{String}] all druids in the supplied Hash
    def druid_array(response, params = {})
      return_list = []
      response.each do |key, items|
        next if key == @@counts_key
        items.each do |item|
          next if item['druid'].nil?
          druid = item['druid'].downcase
          return_list << (params[:no_prefix] ? druid.gsub('druid:', '') : druid)
        end
      end
      return_list
    end

    # Synthesize URL from base, druid and params
    # @see #query_api for args
    # @return [String] URL
    def query_url(base, druid, params)
      url = "#{@site}/#{base}"
      url += "/#{druid}" unless druid.nil? || druid.empty?
      url += add_params(params).to_s unless params.nil? || params.empty?
      url
    end

    # Query a RESTful API and return the JSON result as a Hash
    # @param base [String] The name of controller of the Rails App you wish to route to
    # @param druid [String] The druid/pid of the object you wish to query, or empty string for no specific druid
    # @param params [Hash] we expect :count_only or any of @@supported_params
    # @option params [Hash] :count_only
    # @return [Hash,Integer] All objects governed by the APO including pid/druid, title, date last modified, and count -- or just the count if :count_only
    def query_api(base, druid, params)
      url = query_url(base, druid, params)
      begin
        # We use RestClient::Request.execute here for the longer timeout option
        resp = RestClient::Request.execute(:method => :get, :url => url, :timeout => 180)
      rescue RestClient::Exception => e
        warn "Connection Error with url #{url}: #{e.message}"
        raise e
      end

      # RestClient monkey patches its response so it looks like a string, but really isn't.
      # If you just dd resp.to_i, you'll get the HTML Code, normally 200, not the actually body text you want
      return resp[0..resp.size].to_i if params[:count_only] == true
      JSON[resp] # Convert the response JSON to a Ruby Hash
    end

    # Transform a parameter hash into a RESTful API parameter format
    # @param input_params [Hash{Symbol=>Object}] The existing parameters, eg time and tag
    # @return [String] parameters in the Hash now formatted into a RESTful parameter string
    def add_params(input_params)
      uri = Addressable::URI.new
      uri.query_values = input_params.select { |key, _val| @@supported_params.include?(key) }
      '?' + uri.query.gsub('count_only=true', @@count_only_param)
    end
  end
end
