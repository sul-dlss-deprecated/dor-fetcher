require "spec_helper"

describe DorFetcher::Client do
  describe "Preparing input for RESTful API calls" do
    before(:each) do
      @df = DorFetcher::Client.new(:skip_heartbeat=> true)
      @bad_init_url = "http://umich.edu/~carrickr"
    end

    it "should initialize by default with a URL point to http://127.0.0.1:3000" do
        expect(@df.service_url).to eq("http://127.0.0.1:3000")
    end
  
    it "should initialize to any URL you provide it with heartbeat skipped" do
     url = 'http://wwww.test-url.com'
     df = DorFetcher::Client.new(:service_url => url, :skip_heartbeat=> true)
     expect(df.service_url).to eq(url)
    end
    
    it "should be able to query the provided fetcher url service that is alive" do
      VCR.use_cassette('good_heartbeat_check') do
        df = DorFetcher::Client.new
        expect(df.is_alive?).to eq(true)
      end
    end
    
    it "should check to the service version info" do
      VCR.use_cassette('version_info') do
        df = DorFetcher::Client.new
        version_info = df.service_info
        expect(version_info['app_name']).to eq('DORFetcherService')
      end
    end
    
    it "should fail to initialize when a bad url is provided" do
      VCR.use_cassette('bad_heartbeat_check') do
        expect {DorFetcher::Client.new(:service_url => @bad_init_url)}.to raise_error
      end
    end
    
    it "should detect when a fetcher url has stopped responding" do
      VCR.use_cassette('bad_heartbeat_check') do
        df = DorFetcher::Client.new(:service_url => @bad_init_url, :skip_heartbeat => true)
        expect(df.is_alive?).to eq(false)
      end
    end
  
    it "should add only the count only parameter to an empty hash" do
      params = {} 
      expect(@df.add_count_only_param(params)).to eq({:count_only => true})
    end
  
    it "should add only the count only parameter to a hash with keys" do
      params = {:first_modified => 'foo', :last_modified => 'bar'} 
      expect(@df.add_count_only_param(params)).to eq(params.merge!(count_only: true))
    end

    it "it should only add supported params to a RESTful API Call" do
      params = {:first_modified => 'foo', :last_modified=> 'bar', :fred => 'carl'}
      expect(@df.add_params(params)).to eq("?first_modified=foo&last_modified=bar")
    end
  
    it "it should properly add one parameter to a RESTful API Call" do
      params = {:first_modified => 'foo'}
      expect(@df.add_params(params)).to eq("?first_modified=foo")
    end
  
    it "it should properly translate :count_only=>true to rows=0" do
      expect(@df.add_params(@df.add_count_only_param({}))).to eq("?rows=0")
    end
  
    it "druid_array should take in JSON and return a list of just the druids" do
      input = JSON['{"collections":[{"druid":"druid:yg867hg1375","latest_change":"2013-11-11T23:34:29Z","title":"Francis E. Stafford photographs, 1909-1933"}],"items":[{"druid":"druid:jf275fd6276","latest_change":"2013-11-11T23:34:29Z","title":"Album A: Photographs of Chinas natural landscapes, urban scenes, cultural landmarks, social customs, and people."},{"druid":"druid:nz353cp1092","latest_change":"2013-11-11T23:34:29Z","title":"Album E: Photographs of the Seventh Day Adventist Church missionaries in China"},{"druid":"druid:tc552kq0798","latest_change":"2013-11-11T23:34:29Z","title":"Album D: Photographs of Chinas natural landscapes, urban scenes, cultural landmarks, social customs, and people."},{"druid":"druid:th998nk0722","latest_change":"2013-11-11T23:34:29Z","title":"Album C: Photographs of the Chinese Revolution of 1911 and the Shanghai Commercial Press"},{"druid":"druid:ww689vs6534","latest_change":"2013-11-11T23:34:29Z","title":"Album B: Photographs of Chinas natural landscapes, urban scenes, cultural landmarks, social customs, and people."}],"counts":{"collections":1,"items":5,"total_count":6}}']
      expected_output = ["druid:yg867hg1375", "druid:jf275fd6276", "druid:nz353cp1092", "druid:tc552kq0798", "druid:th998nk0722", "druid:ww689vs6534"]
      expect(@df.druid_array(input)).to eq(expected_output)
    end

    it "druid_array should take in JSON and return a list of just the druids, stripping off druid prefix if requested" do
      input = JSON['{"collections":[{"druid":"DRUID:yg867hg1375","latest_change":"2013-11-11T23:34:29Z","title":"Francis E. Stafford photographs, 1909-1933"}],"items":[{"druid":"druid:jf275fd6276","latest_change":"2013-11-11T23:34:29Z","title":"Album A: Photographs of Chinas natural landscapes, urban scenes, cultural landmarks, social customs, and people."},{"druid":"druid:nz353cp1092","latest_change":"2013-11-11T23:34:29Z","title":"Album E: Photographs of the Seventh Day Adventist Church missionaries in China"},{"druid":"druid:tc552kq0798","latest_change":"2013-11-11T23:34:29Z","title":"Album D: Photographs of Chinas natural landscapes, urban scenes, cultural landmarks, social customs, and people."},{"druid":"druid:th998nk0722","latest_change":"2013-11-11T23:34:29Z","title":"Album C: Photographs of the Chinese Revolution of 1911 and the Shanghai Commercial Press"},{"druid":"druid:ww689vs6534","latest_change":"2013-11-11T23:34:29Z","title":"Album B: Photographs of Chinas natural landscapes, urban scenes, cultural landmarks, social customs, and people."}],"counts":{"collections":1,"items":5,"total_count":6}}']
      expected_output = ["yg867hg1375", "jf275fd6276", "nz353cp1092", "tc552kq0798", "th998nk0722", "ww689vs6534"]
      expect(@df.druid_array(input,{:no_prefix=>true})).to eq(expected_output)
    end
  end
  
  describe "Calling RESTful API and processing output" do
    before(:each) do
      @df = DorFetcher::Client.new(:skip_heartbeat=> true)
    end
    
    it "should return a Hash of all items in a collection and the collection object" do
      VCR.use_cassette('revs_collection_object_call') do
        expected_result = JSON['{"collections":[{"druid":"druid:nt028fd5773","latest_change":"2014-06-06T05:06:06Z","title":"The Revs Institute for Automotive Research, Inc."},{"druid":"druid:wy149zp6932","latest_change":"2014-06-06T05:06:06Z","title":"The George Phillips Collection of the Revs Institute"},{"druid":"druid:yt502zj0924","latest_change":"2014-06-06T05:06:06Z","title":"TThe Bruce R. Craig Collection of the Revs Institutee"}],"items":[{"druid":"druid:bb001zc5754","latest_change":"2014-06-06T05:06:06Z","title":"French Grand Prix and 12 Hour Rheims: 1954"},{"druid":"druid:bb004bn8654","latest_change":"2014-06-06T05:06:06Z","title":" Bryar 250 Trans-American: 1966"},{"druid":"druid:bb013sq9803","latest_change":"2014-06-06T05:06:06Z","title":"Swedish Grand Prix: 1976"},{"druid":"druid:bb014bd3784","latest_change":"2014-06-06T05:06:06Z","title":"Bridgehampton Double 500: 1964"},{"druid":"druid:bb023nj3137","latest_change":"2014-06-06T05:06:06Z","title":"Snetterton Vanwall Trophy: 1958"},{"druid":"druid:bb027yn4436","latest_change":"2014-06-06T05:06:06Z","title":"Crystal Palace BARC: 1954"},{"druid":"druid:bb048rn5648","latest_change":"2014-06-06T05:06:06Z","title":"Tourist Trophy Goodwood: 1959"},{"druid":"druid:bb113tm9924","latest_change":"2014-06-06T05:06:06Z","title":"Permatex 300 NASCAR Race: 1968"}],"counts":{"collections":3,"items":8,"total_count":11}}']
        expect(@df.get_collection('nt028fd5773')).to eq(expected_result)
      end
    end
    
    it "should return a count for the collection" do
      VCR.use_cassette('revs_collection_object_count_call') do
        expect(@df.get_count_for_collection('nt028fd5773')).to eq(11)
      end
    end
    
    it "should return a hash of all collections" do
      expected_result = JSON['{"collections":[{"druid":"druid:nt028fd5773","latest_change":"2014-06-06T05:06:06Z","title":"The Revs Institute for Automotive Research, Inc."},{"druid":"druid:wy149zp6932","latest_change":"2014-06-06T05:06:06Z","title":"The George Phillips Collection of the Revs Institute"},{"druid":"druid:yg867hg1375","latest_change":"2013-11-11T23:34:29Z","title":"Francis E. Stafford photographs, 1909-1933"},{"druid":"druid:yt502zj0924","latest_change":"2014-06-06T05:06:06Z","title":"TThe Bruce R. Craig Collection of the Revs Institutee"}],"counts":{"collections":4,"total_count":4}}']
      VCR.use_cassette('all_collection_objects_call') do
        expect(@df.list_all_collections).to eq(expected_result)
      end
    end
    
    it "should return a count of all collections in the digital repo" do
      VCR.use_cassette('all_collection_count_call') do
        expect(@df.total_collection_count).to eq(4)
      end
    end
    
    it "should return a Hash of all objects governed by an APO and the APO object" do
      expected_result = JSON['{"collections":[{"druid":"druid:nt028fd5773","latest_change":"2014-06-06T05:06:06Z","title":"The Revs Institute for Automotive Research, Inc."},{"druid":"druid:wy149zp6932","latest_change":"2014-06-06T05:06:06Z","title":"The George Phillips Collection of the Revs Institute"},{"druid":"druid:yt502zj0924","latest_change":"2014-06-06T05:06:06Z","title":"TThe Bruce R. Craig Collection of the Revs Institutee"}],"adminpolicies":[{"druid":"druid:qv648vd4392","latest_change":"2013-11-11T23:34:29Z","title":"The Revs Institute for Automotive Research"}],"items":[{"druid":"druid:bb001zc5754","latest_change":"2014-06-06T05:06:06Z","title":"French Grand Prix and 12 Hour Rheims: 1954"},{"druid":"druid:bb004bn8654","latest_change":"2014-06-06T05:06:06Z","title":" Bryar 250 Trans-American: 1966"},{"druid":"druid:bb013sq9803","latest_change":"2014-06-06T05:06:06Z","title":"Swedish Grand Prix: 1976"},{"druid":"druid:bb014bd3784","latest_change":"2014-06-06T05:06:06Z","title":"Bridgehampton Double 500: 1964"},{"druid":"druid:bb023nj3137","latest_change":"2014-06-06T05:06:06Z","title":"Snetterton Vanwall Trophy: 1958"},{"druid":"druid:bb027yn4436","latest_change":"2014-06-06T05:06:06Z","title":"Crystal Palace BARC: 1954"},{"druid":"druid:bb048rn5648","latest_change":"2014-06-06T05:06:06Z","title":"Tourist Trophy Goodwood: 1959"},{"druid":"druid:bb113tm9924","latest_change":"2014-06-06T05:06:06Z","title":"Permatex 300 NASCAR Race: 1968"}],"counts":{"collections":3,"adminpolicies":1,"items":8,"total_count":12}}']
      VCR.use_cassette('apo_objects_call') do
        expect(@df.get_apo('druid:qv648vd4392')).to eq(expected_result)
      end 
    end
    
    it "should return a count for the APO" do
      VCR.use_cassette('apo_objects_count_call') do
        expect(@df.get_count_for_apo('druid:qv648vd4392')).to eq(12)
      end
    end
    
    it "should return a hash of all APOs" do
      expected_result = JSON['{"adminpolicies":[{"druid":"druid:qv648vd4392","latest_change":"2013-11-11T23:34:29Z","title":"The Revs Institute for Automotive Research"},{"druid":"druid:vb546ms7107","latest_change":"2014-09-09T15:40:29Z","title":"Stafford Photos"}],"counts":{"adminpolicies":2,"total_count":2}}']
      VCR.use_cassette('all_apos_objects_call') do
        expect(@df.list_all_apos).to eq(expected_result)
      end
    end
    
    it "should return a count of all APOs in the digital repo" do
      VCR.use_cassette('all_apos_count_call') do
        expect(@df.total_apo_count).to eq(2)
      end
    end
    
  end
  
  describe "Query API" do
    before(:each) do
      @df = DorFetcher::Client.new(:skip_heartbeat=> true)
    end
    
    it "should be able to return a count of objects governed by an APO bounded by datetime parameters" do
      druid = "druid:qv648vd4392"
      base = "apos"
      params = {:count_only=>true, :first_modified=>"2014-01-01T05:06:06Z", :last_modified=>"2014-10-19T05:06:06Z"}
      VCR.use_cassette('exercise_date_restrictions') do
        expect(@df.query_api(base, druid, params)).to eq(11)
      end
    end
  end
 
 
end