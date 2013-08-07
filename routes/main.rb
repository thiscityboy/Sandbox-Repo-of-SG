# encoding: utf-8
class MyApp < Sinatra::Application



get "/" do
  erb :main
end

get "/springy" do
	erb :springy, :layout => false
end

  get "/monitor" do
    erb :monitor, :layout => false
  end

  get "/incompatible" do
    erb :incompatible, :layout => false
  end
end
