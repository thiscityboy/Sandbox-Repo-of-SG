module MsgToolbox
	require 'faraday'
	require 'json'
	require 'xmlsimple'
	require 'open-uri'

	###########################
	#
	#   PUBLIC METHODS
	#
	###########################

	##
	#
	# Send an SMS via Catapult
	#
	# Parameters:
	#   mdn - SMS destination
	#   body - content of SMS
	#   shortcode - short code to use when sending SMS
	#
	# Returns:
	#   XML in response body from Catapult
	#
	##
	def self.send_sms(mdn, body, shortcode)
		sender = SmsSender.new
		return sender.send(mdn, body, shortcode)
	end

	##
	#
	# Shorten a URL
	#
	# Parameters:
	#  
	#   long_url - URL to be shortened
	#
	# Returns:
	#   short url
	#
	##
	def self.shorten_url(long_url)
		shortener = UrlShortener.new
	      @short_url = shortener.shorten(long_url)
	end

	##
	#
	# Convenience method to clean supplied MDN of non-numerics
	#
	# Parameters:
	#  
	#   mdn - mdn to be cleaned
	#
	# Returns:
	#   mdn stripped of all non-numeric characters
	#
	##
	def self.clean_mdn(mdn)
		@clean_mdn =mdn.gsub(/[^0-9]/i, '')
	end

	##
	#
	# Retrieve content from Magic Database
	#
	# Parameters:
	#   collection: base collection to search for content
	#   tags: array of tags to use as search criteria
	#
	# Returns:
	#   @objects: array of populated DataObjects
	#
	##
	def self.get_content_by_tag(collection, tags)

		tags_json= '{ "tags": ' + JSON.generate(tags) + '}'
		tags_json = URI::encode(tags_json)
		@url = "http://msg-magic-db.herokuapp.com/api/v1.0/find/objects/#{collection}?q=#{tags_json}"

		retriever = ContentRetriever.new
		@objects = retriever.getContent(@url)
		return @objects

	end

	##
	#
	# Retrieve single document from Magic Database
	#
	# Parameters:
	#   collection: base collection to search for content
	#   id: object id to retrieve
	#
	# Returns:
	#   @objects: array of populated DataObjects
	#
	##
	def self.get_content_by_id(collection, id)

		id_json= '{ "_id": "' + id + '"}'
		id_json = URI::encode(id_json)
		@url = "http://msg-magic-db.herokuapp.com/api/v1.0/find/objects/#{collection}?q=#{id_json}"

		retriever = ContentRetriever.new
		@objects = retriever.getContent(@url)
		return @objects

	end

	##
	#
	#  Find and send incentive offer to user
	#
	# Parameters:
	#   campaignID - incentive campaign id
	#   mdn - user's phone number
	#   shortcode - short code to use when senidng SMS
	#
	# Returns:
	#   FAIL - when no codes available
	#   SUCCESS - when sms sent containing link to offer
	#
	##
	def self.get_offers(campaignID, mdn, shortcode)

		conn = Faraday.new
		conn.basic_auth(ENV['SPLAT_API_USER'], ENV['SPLAT_API_PASS'])

	    #get next code or "no more" message
	    response = conn.get "http://www.vibescm.com/api/incentive_codes/issue/#{campaignID.to_s}.xml?mobile=#{mdn.to_s}"
	    response_hash= XmlSimple.xml_in(response.body)

	    if response_hash.has_key?('message')
	    	return 'FAIL'
	    else
	    	@code = response_hash["code"][0]

	    	conn = Faraday.new
	    	conn.basic_auth('msg', 'OopsIResetItAgain!')

	      #create short URL
	      @coupon_url="http://vzgo2.com/incentive?c=#{campaignID.to_s}&utm_source=#{campaignID.to_s}&offercode=#{@code}"
	      shortener = UrlShortener.new
	      @short_url = shortener.shorten(@coupon_url)
	      #send sms with link to offer
	      @sms_body="For your exclusive offer click: #{@short_url.body}?c=#{@code} Reply HELP for help, STOP to cancel-Msg&data rates may apply"
	      sender = SmsSender.new
	      sender.send(mdn, @sms_body, shortcode)

	      return 'SUCCESS'
	    end

	  end

	##
	#
	# Subscribe mdn , attribute(s)  and custom attributes to catapult campaign.
	#
	# Parameters:
	#   attribute_values - hash of attributes to capture. MDN is required
	#   custom_attributes - hash of custom attributes to create and capture. (optional)
	#   opt_in - boolean for opt_in value - true=bounceback sent; false=no bounceback
	#
	# Returns:
	#   body of response object as XML
	#
	#
	##
	def self.subscribe(campaignId, attribute_values, custom_attributes, opt_in)

		opt = opt_in ? "invite" : "auto"
		@url = "http://www.vibescm.com/api/subscription_campaigns/#{campaignId.to_s}/multi_subscriptions.xml"
		@payload = "<?xml version='1.0' encoding='UTF-8'?><subscriptions><opt_in>#{opt}</opt_in>"

		if custom_attributes
			@payload << "<create_attribute>true</create_attribute>"
		end

		@payload << "<user>"
		if attribute_values[:mdn]
			@payload << "<mobile_phone>#{attribute_values[:mdn]}</mobile_phone>"
		end
		if attribute_values[:first_name]
			@payload << "<first_name type=\"string\">#{attribute_values[:first_name]}</first_name>"
		end
		if attribute_values[:last_name]
			@payload << "<last_name type=\"string\">#{attribute_values[:last_name]}</last_name>"
		end
		if attribute_values[:email]
			@payload << "<email type=\"string\">#{attribute_values[:email]}</email>"
		end
		if attribute_values[:birthday]
			@payload << "<birthday_on type=\"string\">#{attribute_values[:birthday]}</birthday_on>"
		end
		if attribute_values[:gender]
			@payload << "<gender type=\"string\">#{attribute_values[:gender]}</birthday_on>"
		end

		if custom_attributes
			@payload << "<attribute_paths>"
			custom_attributes.each_pair do |key, value|
				@payload << "<attribute_path>#{key.to_s}/#{value.to_s}</attribute_path>"
			end
			@payload << "</attribute_paths>"
		end

		@payload << "</user></subscriptions>"
		puts @url
		puts @payload
		conn = Faraday.new
		conn.basic_auth(ENV['SPLAT_API_USER'], ENV['SPLAT_API_PASS'])
		@response = conn.post do |req|
			req.url @url
			req.headers['Content-Type'] = 'application/xml'
			req.body = @payload
		end

		return @response.body

	end


	def self.simple_subscribe(campaignId, mdn)

		req_payload = '<?xml version=\'1.0\' encoding=\'UTF-8\'?>
		<subscription>
		<user>
		<mobile_phone>' + mdn + '</mobile_phone>
		</user>
		</subscription>'
		@url = "http://www.vibescm.com/api/subscription_campaigns/#{campaignId.to_s}/subscriptions.xml"
		conn = Faraday.new
		conn.basic_auth(ENV['SPLAT_API_USER'], ENV['SPLAT_API_PASS'])
		response = conn.post do |req|
			req.url @url
			req.headers['Content-Type'] = 'application/xml'
			req.body = req_payload
		end
		puts (response.body)
		return response.body
	end

	##
	#
	# Subscribe mdn , attribute(s)  and nested custom attributes to catapult campaign.
	#
	# use case: when custom campaign attributes with same parent are present in campaign (i.e. - interest/music, interest/guest list, etc)
	# because we are using Hashes for our data, we cannot have multiple keys with the same value (in the example above: 'interest'). To deal with 
	# this, set the parent attribute as the key in the custom_attributes hash and the values as an array assigned to that key. Provide the parent name 
	# to this function and the nested attributes will be generated for catapult consumption ( 'interest' => ['music','guest list']).
	#
	# Parameters:
	#   attribute_values - hash of attributes to capture. MDN is required
	#   custom_attributes - hash of custom attributes to create and capture. parent attribute key has array of child values as value
	#   opt_in - boolean for opt_in value - true=bounceback sent; false=no bounceback
	# 	parent_attribute - name of parent custom attribute that contains children
	#
	# Returns:
	#   body of response object as XML
	#
	# TODO: lots of repeated code in this method and subscribe. need to refactor to share.
	##
	  def self.subscribe_with_nested_attributes(campaignId, attribute_values, custom_attributes, parent_attribute, opt_in)

	    opt = opt_in ? "invite" : "auto"
	    @url = "http://www.vibescm.com/api/subscription_campaigns/#{campaignId.to_s}/multi_subscriptions.xml"
	    @payload = "<?xml version='1.0' encoding='UTF-8'?><subscriptions><opt_in>#{opt}</opt_in>"

	    if custom_attributes
	      @payload << "<create_attribute>true</create_attribute>"
	    end

	    @payload << "<user>"
	    if attribute_values[:mdn]
	      @payload << "<mobile_phone>#{attribute_values[:mdn]}</mobile_phone>"
	    end
	    if attribute_values[:first_name]
	      @payload << "<first_name type=\"string\">#{attribute_values[:first_name]}</first_name>"
	    end
	    if attribute_values[:last_name]
	      @payload << "<last_name type=\"string\">#{attribute_values[:last_name]}</last_name>"
	    end
	    if attribute_values[:email]
	      @payload << "<email type=\"string\">#{attribute_values[:email]}</email>"
	    end
	    if attribute_values[:birthday]
	      @payload << "<birthday_on type=\"string\">#{attribute_values[:birthday]}</birthday_on>"
	    end
	    if attribute_values[:gender]
	      @payload << "<gender type=\"string\">#{attribute_values[:gender]}</birthday_on>"
	    end

	    if custom_attributes
	      @payload << "<attribute_paths>"
	      custom_attributes.each_pair do |key, value|
	      	if key.to_s == parent_attribute
	      		value.each do |val|
	      			@payload << "<attribute_path>#{key.to_s}/#{val}</attribute_path>"
	      		end
	      	else
	      		@payload << "<attribute_path>#{key.to_s}/#{value.to_s}</attribute_path>"
	      	end	        
	      end
	      @payload << "</attribute_paths>"
	    end

	    @payload << "</user></subscriptions>"
	    puts @url
	    puts @payload
	    conn = Faraday.new
	    conn.basic_auth(ENV['SPLAT_API_USER'], ENV['SPLAT_API_PASS'])
	    @response = conn.post do |req|
	      req.url @url
	      req.headers['Content-Type'] = 'application/xml'
	      req.body = @payload
	    end

	    return @response.body

	  end

	##
	#
	# Enter a contest campaign.
	#
	# Parameters:
	#   campaignId - campaign to enter
	#   form_values - hash of attributes to capture
	#   custom_attributes - hash of custom attributes to create and capture. (optional)
	#   shortcode - used to send SMS bounceback after entry (optional)
	#
	# Returns:
	#   text of response upon entry as defined in campaign + sms
	#   or text stating they've already entered, if applicable
	#
	##
	def self.enter_contest(campaignId, form_values, custom_attributes, shortcode)

		@payload = "<?xml version='1.0' encoding='UTF-8'?>
		<contest_entry_data>"
		if form_values[:mdn]
			@payload  << "<mobile_phone>#{form_values[:mdn]}</mobile_phone>"
		end
		if form_values[:first_name]
			@payload  << "<first_name>#{form_values[:first_name]}</first_name>"
		end
		if form_values[:last_name]
			@payload  << "<last_name>#{form_values[:last_name]}</last_name>"
		end                        
		if form_values[:email]
			@payload  << "<email>#{form_values[:email]}</email>"
		end                         
		if form_values[:date_of_birth]
			@payload  << "<birthday>#{form_values[:date_of_birth]}</birthday>"
		end    
		if form_values[:phone]
			@payload  << "<phone>#{form_values[:phone]}</phone>"
		end
		if form_values[:street_address]
			@payload  << "<street_address>#{form_values[:street_address]}</street_address>"
		end    
		if form_values[:city]
			@payload  << "<city>#{form_values[:city]}</city>"
		end    
		if form_values[:state_code]
			@payload  << "<state_code>#{form_values[:state_code]}</state_code>"
		end   
		if form_values[:postal_code]
			@payload  << "<postal_code>#{form_values[:postal_code]}</postal_code>"
		end   
		if custom_attributes
			@payload << "<custom_attributes>"
			custom_attributes.each_pair do |key, value|
				@payload << "<#{key.to_s}>#{value.to_s}</#{key.to_s}>"
			end
			@payload << "</custom_attributes>"
		end                          
		@payload  <<  "</contest_entry_data>"

		conn = Faraday.new
		conn.basic_auth(ENV['SPLAT_API_USER'], ENV['SPLAT_API_PASS'])
		response = conn.post do |req|
			req.url  "http://www.vibescm.com/api/amoe/enter.xml?id=#{campaignId}"
			req.headers['Content-Type'] = 'application/xml'
			req.body = @payload
		end
		res_hash= XmlSimple.xml_in(response.body)
		if res_hash.has_key?('bad-request')
			@msg =  res_hash["bad-request"][0]
		else
			@msg =  res_hash["ok"][0]
		end
		if shortcode 
			sender = SmsSender.new
			sender.send(form_values[:mdn], @msg, shortcode)	
		end	
	end

	##
	#
	# Sign an autograph image.
	#
	# Parameters:
	#   name - name to sign image with
	#   baseImageId - ID of base image as defined in MSG-Toolbox Image API
	#
	# Returns:
	#   Error code indicating name was forbidden
	#   or URL to signed image
	#
	##
	def self.sign_autograph(name, baseImageId)
		conn = Faraday.new
		conn.basic_auth(ENV['MSG_API_USER'], ENV['MSG_API_PASS'])

		@response = conn.get "http://msg-toolbox.apps1.vibescm.com/api/image/sign/#{name.titleize}/#{baseImageId}"
		@response_hash = JSON.parse(@response.body)

		if @response_hash.has_key?('errorCode')
			return @response_hash['errorCode']
		else
			return @response_hash['imageName']
		end

	end

	def self.send_international_sms(mdn, body)
		conn = Faraday.new
		@response = conn.get "http://list.lumata.com/wmap/SMS.html?User=msuk_vibes&Password=v1b3s4uk&Type=SMS&Body="+body+"+Vibes&Phone="+mdn+"&Sender=Vibes"
		@response.body["<html>"] = ""
		@response.body["</html>"] = ""
		@response.body["<body>"] = ""
		@response.body["</body>"] = ""
		return @response.body
	end

	  # TODO: Need to get splat api user access to carrier lookup
	  #  def self.get_carrier_code(mdn)
	  #    puts 'getting carrier code'
	  #        conn = Faraday.new 'https://api.vibes.com', :ssl => {:verify => false}
	  #        conn.basic_auth(ENV['SPLAT_API_USER'], ENV['SPLAT_API_PASS'])
	  #        response = conn.get "/MessageApi/mdns/"+ mdn.to_s
	  #puts response.body
	  #        res_hash= XmlSimple.xml_in(response.body)
	  #        return res_hash['carrier']
	  #  end

	  def self.get_carrier_code(mdn)

	  	require 'net/http'
	  	require 'nokogiri'

	    #Scramble
	    ab = 'A134'
	    xy = 'gbPSM2'
	    ab = ab.gsub('3', '')
	    xy = xy.gsub('2', '')

	    #PUT Create Subscription
	    un = 'Vibes rb@jbrb.com'
	    pw = xy + ab

	    uri = URI.parse('https://api.vibes.com/MessageApi/mdns/' + mdn.to_s)
	    #uri = URI.parse('http://connprod04.prod.vibes.com:8080/MessageApi/mdns/' + mdn.to_s)
	    http = Net::HTTP.new(uri.host, uri.port)
	    http.use_ssl = true
	    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	    req = Net::HTTP::Get.new(uri.request_uri)
	    req.add_field("Authorization", un + ":" + pw)
	    res = http.request(req)
	    puts res.body
	    doc = Nokogiri::XML(res.body)
	    @doc = doc.xpath('//mdn').each do |record|
	    	@carriercode = record.at('@carrier').text
	    end

	    return @carriercode

	  end

	  ###########################
	#
	#   PRIVATE NESTED CLASSES
	#
	###########################

	
	class SmsSender
		def send(mdn, body, shortcode)
			conn = Faraday.new
			conn.basic_auth(ENV['MSG_API_USER'], ENV['MSG_API_PASS'])
			response = conn.post do |req|
				req.url "http://msg-toolbox.apps1.vibescm.com/api/v2/message.xml/send/#{shortcode.to_s}/#{mdn.to_s}"
				req.headers['Content-Type'] = 'application/xml'
				req.body = body
			end
			puts '++++++++++++ SMS Sender response: ' + response.body
			return response.body
		end
	end

	class UrlShortener
		def shorten(url)
			# conn = Faraday.new 'https://trustapi2.vibesapps.com/', ssl: {verify: false}
			conn = Faraday.new
	    		conn.basic_auth(ENV['SHORT_USER'], ENV['SHORT_PASS'])
		      #create short URL
		      resp = conn.get "http://trustapi.vibesapps.com/UrlShortener/api/shorten?url=#{url}"
		      #resp = conn.get "/UrlShortener/api/shorten?url=#{url}"
		      @short_url = resp.body
		end
	end

	
	class ContentRetriever
		def getContent(url)
			conn = Faraday.new
			conn.basic_auth(ENV['MSG_MAGIC_USER'], ENV['MSG_MAGIC_PASS'])

			response = conn.get url
			results = JSON.parse(response.body)
			@objects = Array.new

			results.each do |result|
				object = DataObject.new(result)
				@objects.push(object)
			end
			return @objects
		end
	end

	class DataObject
		def initialize(hash)
			hash.each do |k, v|

	        ## create and initialize an instance variable for this key/value pair
	        self.instance_variable_set("@#{k}", v)

	        ## create the getter that returns the instance variable
	        self.class.send(:define_method, k, proc { self.instance_variable_get("@#{k}") })

	        ## create the setter that sets the instance variable
	        self.class.send(:define_method, "#{k}=", proc { |v| self.instance_variable_set("@#{k}", v) })
	      end
	    end
	  end

	end
