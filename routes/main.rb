# encoding: utf-8
class MyApp < Sinatra::Application
	get "/" do
		@title = "Welcome to MyApp"				
		erb :main
	end
end