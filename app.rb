require 'sinatra'
require 'sinatra/flash'
require 'sinatra/reloader'
require 'mongo'
require 'json'
require 'csv'
require_relative 'minify_resources'

class MyApp < Sinatra::Application
  register Sinatra::Reloader
  enable :sessions

  #uncomment to add mongo support
  #
  # configure do
  #   mongouri = ENV['MONGOLAB_URI']
  #   uri = URI.parse(mongouri)
  #   $conn = Mongo::Connection.from_uri(mongouri)
  #   $db = $conn.db(uri.path.gsub(/^\//, ''))
  # end

  configure :production do
    set :clean_trace, true
    set :css_files, :blob
    set :js_files, :blob
    MinifyResources.minify_all
  end

  configure :development do
    set :css_files, MinifyResources::CSS_FILES
    set :js_files, MinifyResources::JS_FILES
  end

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html
  end
end

require_relative 'helpers/init'
require_relative 'models/init'
require_relative 'routes/init'