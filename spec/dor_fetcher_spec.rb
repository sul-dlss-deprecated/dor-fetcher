require "spec_helper"

describe DorFetcher::Client do
  it "should initialize by default with a URL point to http://127.0.0.1:3000" do
    df = DorFetcher::Client.new
    expect(df.service_url).to eq("http://127.0.0.1:3000")
  end
  
  it "should initialize to any URL you provide it" do
   url = 'http://wwww.test-url.com'
   df = DorFetcher::Client.new(:service_url => url)
   expect(df.service_url).to eq(url)
   
  end
  
  it "druids_array should take in JSON and return a list of just the druids" do
    input = "{\"collection\":[{\"druid\":\"druid:yg867hg1375\",\"latest_change\":\"2013-11-11T23:34:29Z\",\"title\":[\"Francis E. Stafford photographs, 1909-1933\"]}],\"item\":[{\"druid\":\"druid:jf275fd6276\",\"latest_change\":\"2013-11-11T23:34:29Z\",\"title\":[\"Album A: Photographs of China's natural landscapes, urban scenes, cultural landmarks, social customs, and people.\"]},{\"druid\":\"druid:nz353cp1092\",\"latest_change\":\"2013-11-11T23:34:29Z\",\"title\":[\"Album E: Photographs of the Seventh Day Adventist Church missionaries in China\"]},{\"druid\":\"druid:tc552kq0798\",\"latest_change\":\"2013-11-11T23:34:29Z\",\"title\":[\"Album D: Photographs of China's natural landscapes, urban scenes, cultural landmarks, social customs, and people.\"]},{\"druid\":\"druid:th998nk0722\",\"latest_change\":\"2013-11-11T23:34:29Z\",\"title\":[\"Album C: Photographs of the Chinese Revolution of 1911 and the Shanghai Commercial Press\"]},{\"druid\":\"druid:ww689vs6534\",\"latest_change\":\"2013-11-11T23:34:29Z\",\"title\":[\"Album B: Photographs of China's natural landscapes, urban scenes, cultural landmarks, social customs, and people.\"]}],\"counts\":[{\"collection\":1},{\"item\":5},{\"total_count\":6}]}"
    expected_output = ['foo']
  
  end
  
end