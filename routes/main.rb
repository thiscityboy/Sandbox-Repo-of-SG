# encoding: utf-8
class MyApp < Sinatra::Application
	get "/" do
		@title = "Welcome to MyApp"	
		erb :main
	end

	get "/monitor" do
		erb :monitor, :layout => false
	end

	get "/incompatible" do
		erb :incompatible, :layout => false
	end
end