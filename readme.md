# Sinatra template for Monk: http://monkrb.com

### Run these commands ONCE:
    gem install monk
    monk add sinatra git@git.vibes.com:msg-monk-sinatra.git 

### Then, when you need a new Sinatra app, create an empty project directory, navigate to it from the command line and run:
    monk init -s sinatra

Boom. Instant Sinatra project.

### File Layout:

	Gemfile
	config.ru
	app.rb
	start.sh
	helpers/
		init.rb
		partials.rb
	models/
		init.rb
		user.rb
	routes/
		init.rb
		main.rb
	views/
		layout.erb
		main.erb
 

