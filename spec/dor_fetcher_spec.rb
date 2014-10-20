require "spec_helper"

describe DorFetcher::Client do
  describe "Preparing input for RESTful API calls" do
    before(:each) do
      @df = DorFetcher::Client.new
    end

    it "should initialize by default with a URL point to http://127.0.0.1:3000" do
      expect(@df.service_url).to eq("http://127.0.0.1:3000")
    end
  
    it "should initialize to any URL you provide it" do
     url = 'http://wwww.test-url.com'
     df = DorFetcher::Client.new(:service_url => url)
     expect(df.service_url).to eq(url)
   
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
  
    it "druids_array should take in JSON and return a list of just the druids" do
      input = JSON['{"collection":[{"druid":"druid:yg867hg1375","latest_change":"2013-11-11T23:34:29Z","title":["Francis E. Stafford photographs, 1909-1933"]}],"item":[{"druid":"druid:jf275fd6276","latest_change":"2013-11-11T23:34:29Z","title":["Album A: Photographs of Chinas natural landscapes, urban scenes, cultural landmarks, social customs, and people."]},{"druid":"druid:nz353cp1092","latest_change":"2013-11-11T23:34:29Z","title":["Album E: Photographs of the Seventh Day Adventist Church missionaries in China"]},{"druid":"druid:tc552kq0798","latest_change":"2013-11-11T23:34:29Z","title":["Album D: Photographs of Chinas natural landscapes, urban scenes, cultural landmarks, social customs, and people."]},{"druid":"druid:th998nk0722","latest_change":"2013-11-11T23:34:29Z","title":["Album C: Photographs of the Chinese Revolution of 1911 and the Shanghai Commercial Press"]},{"druid":"druid:ww689vs6534","latest_change":"2013-11-11T23:34:29Z","title":["Album B: Photographs of Chinas natural landscapes, urban scenes, cultural landmarks, social customs, and people."]}],"counts":[{"collection":1},{"item":5},{"total_count":6}]}']
      expected_output = ["druid:yg867hg1375", "druid:jf275fd6276", "druid:nz353cp1092", "druid:tc552kq0798", "druid:th998nk0722", "druid:ww689vs6534"]
      df = DorFetcher::Client.new
      expect(df.druid_array(input)).to eq(expected_output)
    end
  end
 
end