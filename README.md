# dor-fetcher
[<img src="https://travis-ci.org/sul-dlss/dor-fetcher.svg" alt="Build Status"/>](https://travis-ci.org/sul-dlss/dor-fetcher)
[<img src="https://coveralls.io/repos/sul-dlss/dor-fetcher/badge.png" alt="Coverage Status"/>](https://coveralls.io/r/sul-dlss/dor-fetcher)
[<img src="https://badge.fury.io/rb/dor-fetcher.svg" alt="Gem Version" />](http://badge.fury.io/rb/dor-fetcher)
[<img src="https://gemnasium.com/sul-dlss/dor-fetcher.svg" alt="Dependency Status"/>](https://gemnasium.com/sul-dlss/dor-fetcher)

This gem provides a basic wrapper for reaching the API of an instance of
dor-fetcher-service: https://github.com/sul-dlss/dor-fetcher-service.  This
ReadMe assumes your familiar with the API of dor-fetcher-service, its JSON
return and are just looking to leverage that with this gem.

By default you will only get fully accessioned objects in your result set.
There is a parameter you can specify to return all objects, but you cannot restrict these by date.

## Usage

Add dor-fetcher to your Gemlist and require it where appropriate.
```ruby
gem 'dor-fetcher'
```
Example:
```ruby
require 'dor-fetcher'
df = DorFetcher::Client.new # defaults to localhost:3000
df = DorFetcher::Client.new(:service_url => 'http://YOUR_URL_HERE') # override default
df.list_all_apos # perform client actions
```

## Doing Things With This Gem

### Parameters

A Hash can be passed anywhere you see params listed as an argument.  
You do not need to include an empty hash if you have no parameters.  For example,
you can do `df.get_count_for_apo(apo_druid)` or `df.get_count_for_apo(apo, {:count_only=>true})`,
but you don't need to do `df.get_count_for_apo(apo_druid, {})`.

* `:count_only => true` This returns just a count of the results.  Defaults to false.
* `:first_modified => 'String_of_Time_In_ISO8601_Format'` This sets the first datetime that the object was modified, will default to the start of POSIX Time (Thursday, 1 Jan 1970).
* `:last_modified => 'String_of_Time_In_ISO8601_Format'` This sets the last datetime that the object was modified, will default to tomorrow.
* `:status => 'registered'` This will return ALL objects, even those not accessioned.  If you leave this off, you will ONLY get accessioned objects.  
  If this parameter is set, you cannot use the first_modified and last_modified parameters, they will be ignored since they only apply to published dates.

You do not need both a :first_modified and a :last_modified, you can use one or both.

### A Note On The Druid: Prefix

You can pass your druid in as druid:PID or just PID.  dor-fetcher-service can
handle both forms and this gem is just the messenger.  If we ever update
dor-fetcher-service to require the druid: prefix and forget to update this
README, obviously we will have a problem.  As such best practice is include
the prefix on anything you plan on putting in production and supporting for a
long period of time.

### Listing All of Something

*   Admin Policy Objects: `df.list_all_apos`
*   Collections: `df.list_all_collections`

### Getting The Counts of Something

#### Total Counts Of One Type

*   Admin Policy Objects: `df.total_apo_count`
*   Collections: `df.total_collection_count`

#### Total Counts Of Objects That Are Part of Something

*   Admin Policy Objects: `df.get_count_for_apo(apo_druid, params)`
*   Collection Objects: `df.get_count_for_collection(collection_druid, params)`

### Getting The Members of Something

*   Admin Policy Objects: `df.get_apo(apo_druid, params)`
*   Collections: `df.get_collection(collect_druid, params)`

The above returns a hash of all members of the collection, unless you pass in
`:count_only => true` as a param.  If you're doing that though, why not use the
`df.get_count_for_OBJECT` methods?

### Advanced Querying

Use: `df.query_api(base, druid, params)` To produce the call:

    http://SERVICE-URL/BASE/DRUID?PARAM1=foo?PARAM2=bar?etc

### I Just Want An Array Of Druids

Wrap any of the calls above in df.druid_array to produce just an array of
druids.  This array will contain the druid prefix.  Example call:

```ruby
df.druid_array(df.list_all_collections)
```

## To Develop This Gem Locally:

*   Clone From Github: `git clone https://github.com/sul-dlss/dor-fetcher`
*   Create your feature branch: `git checkout -b my-new-feature`
*   Write code and tests
*   If writing tests that rely on network calls you need to make a VCR cassette for them or it will fail.
*   If old cassettes are broken, remove them from `spec/fixtures/vcr_casettes`, bring up a local instance of **dor-fetcher-service** and new ones will automatically record
*   Ensure all the tests passes via `rake rspec`
*   Merge back into master
*   Bump the version in the gemspec
*   Update the date in the gemspec
*   Release to RubyGems via `rake release`

## Command Line Usage

If you have the gem code checked out, you can execute gem commands on the
command line by running "bin/console".  This gives you a Ruby console with the gem loaded:

```bash
bin/console
```

```ruby
fetch = DorFetcher::Client.new(:service_url => 'http://dorfetcher-prod.stanford.edu')
fetch.list_all_apos
```

## Building and Installing Locally

In the gem directory:

```bash
gem build dor-fetcher.gemspec
gem install ./DorFetcher-#.#.#.gem # Replace the # with the version of the gem built, the build command will display this in console)
irb
```

Then in irb:

```ruby
require 'dor-fetcher'
# Do Stuff in IRB
```

If all you need to do is test the gem in IRB, you can also use `bin/console`.
