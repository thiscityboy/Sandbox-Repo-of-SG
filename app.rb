require 'sinatra'
require 'sinatra/flash'
require 'sinatra/reloader'
require 'sinatra/cookies'
require 'mongo_mapper'
require 'json'

require_relative 'minify_resources'

class MyApp < Sinatra::Application
  register Sinatra::Reloader
  set :protection, :except => :frame_options
  enable :sessions
  set :session_secret, ENV["SECRET_TOKEN"] || '03c9fe100fcf579cd70229898381157898423345673849e10d0c54121cc37bda6a66ec2ae3'

  #uncomment to add mongo support
  # configure do
  #   mongouri = ENV['MONGOLAB_URI']
  #mongomapper
  #   uri = URI.parse(mongouri)
  #   MongoMapper.connection = Mongo::Connection.new(uri.host, uri.port)
  #   MongoMapper.database = uri.path.gsub(/^\//, '')
  #   MongoMapper.database.authenticate(uri.user, uri.password)
  #ruby driver
  # $conn = Mongo::MongoClient.from_uri(mongouri, :pool_size => 15)
  # $db = $conn.db(uri.path.gsub(/^\//, ''))
  # end

  configure :production do
    set :clean_trace, true
    set :css_files, :blob
    set :js_files, :blob
    MinifyResources.minify_all
    #ensure stdout logging ("puts") shows up in heroku
    $stdout.sync = true
  end

  configure :development do
    require 'better_errors'
    set :css_files, MinifyResources::CSS_FILES
    set :js_files, MinifyResources::JS_FILES
    use BetterErrors::Middleware
  end

  helpers do
    include Rack::Utils
    include Sinatra::Cookies
    alias_method :h, :escape_html
  end
end

#
# basic auth requires the following three environment variables be set:
# ENV['BASIC_USER']
# ENV['BASIC_PW']
# ENV['BASIC_REALM']
#
# set the ENV vars and uncomment the following line to enable basic auth
# require_relative 'lib/sinatra/basic_auth'

require_relative 'helpers/init'
require_relative 'models/init'
require_relative 'routes/init'
