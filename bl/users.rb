$users = $mongo.collection('users')

$users.indexes.create_one({email: 1}, unique: true) rescue nil

USER_KEYS = ["email",  "name", "handle", "img_url", "timezone", 
	"contact_me", "title", "subtitle", "desc", "lang", "country",
	 "location", "my_theme", "media", "payout_info", "tags", 
	 "media_object_fit"] + SOCIAL_NETWORKS

DEFAULT_IMG = DEFAULT_PIC = '/img/profile.png'

get '/me' do
	redirect_unless_user

	erb :'me/me', default_layout
end

get '/me/analytics' do
	redirect_unless_user

	erb :'me/analytics', default_layout
end

get '/create' do
	redirect '/casts/create' if !pr[:k] # to ensure querystring 
	redirect_unless_user

	erb :'/create/create', default_layout
end

get '/my_programs' do 
	erb :'/users/my_programs', default_layout
end

post '/update_me' do
	redirect_unless_user

	# gather media input into single array of objects

	pr[:media]         = []
	pr[:media_types] ||= [] #sent alongsides the URLs arr
	pr[:media_img].to_a.each_with_index { |url, idx| pr[:media].push({type: pr[:media_types][idx], url: url}) }

	data = pr.just_keys(USER_KEYS)

	data[:handle].to_s.gsub!(/[^0-9A-Za-z]/, '')
	data[:timezone] = data[:timezone].to_i
	# if (user = $users.get(handle: data[:handle])) && (user[:_id]!=cuid)
	# 	flash_err 'Handle is taken.'
	# 	redirect '/me'
	# end

	user = $users.update_id(cu['_id'],data)
	flash.message = 'Updated!'

	redirect back
end

if !$prod
	get '/sella' do
		redirect '/' if $prod
		return unless !$prod
		session[:user_id] = sella[:_id]
		redirect '/me'
	end
end

get '/logout' do
	session.clear 
	flash.message = 'See you next time!'
	redirect '/'
end

WELCOME_MSG = "Hi, this is mindy. You will be receiving mindful messages from this number. No need to reply. Have a great day. :)"

def reset_all_login_tokens
	$users.all.each {|u| set_login_token(u) }
end

def set_login_token(user)
	$users.update_id(user['_id'], {token: guid})
end

def clean_user(user)
	# public fields available for all
	(user || {}).just(:_id, :img_url, :handle, :verified, :geographic_area, :lang, :desc, :location, :tags)
rescue => e 
	log_e(e)
	{}
end

def verify_signup_data
	if pr[:name] == 'test' || (pr[:email] == 'test')
		num        = nice_id
		pr[:name]  = "Name "+num
		pr[:email] = "email_#{num}@domain.com"
	end

	email    = pr[:email].to_s.downcase
	password = pr[:password].to_s.downcase
	name     = pr[:name].to_s.downcase	

	if !valid_email(email)
		if pr[:ajax] 
			halt(401,{err: 'Invalid email.'}) 
		else 
			flash_err('Invalid email.') 
			redirect '/signup'
		end
	elsif !(email.present? && name.present?)
		if pr[:ajax] 
			halt(401,{err: 'Missing email or name.'})
		else 
			flash_err('Missing email or name.') 
			redirect '/signup'
		end
	end

	if email == 'test'		
		$users.delete_one({email: 'test'})
	end

	if (user = $users.get(email: email))
		if pr[:ajax]
			halt(401,{err: 'Email taken. Perhaps try to log in?', goto: "/login?email=#{email}&go_back_to=#{pr[:go_back_to]}"})
		else 
			flash_err('Email taken.')
			redirect '/signup'
		end
	end
end

def add_user
	email    = pr[:email].to_s.downcase	
	password = pr[:password].to_s.downcase
	name     = pr[:name].to_s.downcase

	timezone = (pr[:timezone] || 0).to_i
	
	handle   = $users.available_field('handle', name.split(/@/).first).to_s.strip.downcase

	data = {email: email, name: name, handle: handle, img_url: '/img/profile.png', timezone: timezone}
	# data[:style]    = pr[:style] || DEFAULT_BRAND
	data[:password]   = BCrypt::Password.create(password) if password.present?
	data[:referrer]   = session[EXTERNAL_REFERER] if session[EXTERNAL_REFERER]
	data[:contact_me] = pr[:contact_me].to_s == 'on'
	data[:referrer_id]= pr[:referrer_id] 
	
	u = user = $users.add(data)


	# add_default_casts(user)
	send_welcome_email(user)

	session[:user_id] = user[:_id] 
	if pr[:ajax] 
		{msg: "signed up"}
	else 
		flash.message = 'Welcome to nowcast.'
		if pr[:event_title] #signup and create event at once
			redirect "/casts/create?event_title=#{pr[:event_title]}"
		else 
			redirect '/me'
		end
	end
end

def user_link(user)
	"/@#{user[:handle]}"
end

def user_location_for_header(user)
	return user[:location]
	# loc     = ""
	# city    = user[:city].to_s
	# country = user[:country].present? ? (COUNTRIES.find {|c| c[:val] == user[:country] })[:label] : ''
	# if city.present? && country.present?
	# 	"#{city}, #{country}"
	# elsif city.present? || country.present?
	# 	city || country 
	# else
	# 	""
	# end
end

def has_tag(user, tag)
	user[:tags].to_s.downcase.include?(tag.downcase) 
end

post '/signup' do
	verify_signup_data
	res = add_user
end

get '/forgot_password' do
	erb :'home/forgot_password', default_layout
end

get '/login' do
	erb :'home/login', default_layout
end

post '/login' do
	email    = pr[:email].to_s.downcase
	password = pr[:password].to_s.downcase
	user = $users.get(email: email)

	if (user) && (BCrypt::Password.new(user[:password]) == password)
		session[:user_id] = user[:_id]
		flash.message = 'Welcome back.'
		
		redirect (pr[:go_back_to] ? CGI.unescapeHTML(pr[:go_back_to]) : '/me')
	else
		flash.message = 'Wrong username or password, please try again.'		
		redirect '/me'
	end
end

FB_REDIRECT_URI = $root_url + '/fb_login'
FB_SECRET = ENV['FB_APP_SECRET']

get '/fb_login' do 
	code = pr[:code]
	url  = "https://graph.facebook.com/v4.0/oauth/access_token?client_id=472876716648358&redirect_uri=#{FB_REDIRECT_URI}&client_secret=#{FB_SECRET}&code=#{code}"
	res  = http_get_json(url)
	
	{res: res}
end

get '/signup' do
	erb :'home/signup', default_layout
end

get '/email_login' do
	token = pr[:token]

	if user = $users.get(token: token) 
		session[:user_id] = user[:_id]
		$users.update_id(user[:_id], {last_email_login: Time.now, token: nil})
		flash.message = "Welcome back, #{user[:email]}"
		redirect '/'
	else
		flash.message = 'Token expired, please try again.'
		redirect '/login'
	end
end