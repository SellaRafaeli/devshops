puts "starting app..."

require 'bundler'

require 'active_support'
require 'active_support/core_ext'
require 'sinatra/reloader' #dev-only

puts "requiring gems..."

Bundler.require

puts "loading dotenv..."
Dotenv.load

$app_name   = 'devshops'

require './setup'
require './my_lib'

require_all './db'
require_all './admin'
require_all './bl'
require_all './comm'
require_all './logging'
require_all './mw'

include Helpers #makes helpers globally available 

MEDIUMS = ['email', 'sms']

get '/ping' do
	# received_session_bla = session[:bla]
	# session[:bla] = session[:bla].to_i + 1
  {msg: "pong from #{$app_name}", val: 'It is always now', domain: 'good'}
end

get '/ping' do
	{msg: 'fong'}
end

post '/ping' do
  {msg: "post pong from #{$app_name}", val: 'It is always now'}
end

post '/contact' do 

end

get '/login_as/?:handle?' do 
	return if $prod
	handle = pr[:handle]
	user   = $users.get(handle: handle) || $users.random
	session[:user_id] = user[:_id] 
	redirect '/me'
end

get '/gold' do
	redirect '/me' if cu
	erb :'home/home', default_layout
end

def set_brand(brand)
	session[:brand] = brand
end

def get_brand
	return 'DEFAULT_BRAND'
	# if cu 
	# 	cu[:style]
	# else 
	# 	session[:brand] || DEFAULT_BRAND
	# end
end

get '/entrepreneur' do
	# set_brand(ENTREP_MODE)
	erb :'home/home', default_layout
end

get '/invest' do
	erb :'other/invest', default_layout
end

# get '/about' do
# 	erb :'other/about', default_layout
# end

get '/what_is_a_nowcast' do
	erb :'other/what_is_a_nowcast', default_layout
end

get '/get_started' do
	erb :'other/get_started', default_layout
end

get '/start' do
	erb :'other/get_started', default_layout
end

get '/faq' do
	erb :'other/faq', default_layout
end

get '/team' do
	erb :'other/team', default_layout
end

get '/how_it_works' do
	erb :'other/how_it_works', default_layout
end

get '/terms_of_service' do 
	erb :'other/terms_of_service', default_layout
end

get '/privacy_policy' do 
	erb :'other/privacy_policy', default_layout
end

get '/cu' do
	{cu: cu}
end

get '/careers' do
	erb :'other/careers', default_layout
end

get '/contact' do
	erb :'other/contact', default_layout
end

# get '/articles' # see articles.rb 

get '/values' do
	erb :'other/values', default_layout
end

get '/search' do 
	# redirect '/'
	erb :'devshops/search', default_layout
end

get '/accept_cookies' do 
	session[:cookies_accepted] = Time.now
end

get '/test' do
	erb :'other/test', default_layout
end

def is_home
	_req.path == '/'
end

def search_input_on_top
	!(is_home || @fullstack)
end

get '/r/:code' do 
	pr[:state] = 'New York'
	pr[:city]  = 'New York'
	return erb :'search/search', default_layout
end

get '/' do		
	# erb :'other/landing_page'
	pr[:state] = 'New York'
	pr[:city]  = 'New York'
#	return redirect '/r/ny'
	# erb :'search/search', default_layout
	# 
	# erb :'home/cannabis_delivery', default_layout	
	erb :'devshops/index', default_layout	
	# 
end

get '/chat' do 
	erb :'home/home_chat', default_layout	
end

get '/vip' do 
	if cu && cu[:vip]
		erb :'home/home_chat', default_layout.merge(locals: {code: 'vip'})
	else 
		erb :'home/contact_us_for_vip', default_layout
	end
end

get '/zip' do
	redirect '/zip/'+pr[:zip].to_s
end

get '/zip/:code' do 
	code = pr[:zipcode] = pr[:code]
	code = 90210 if code == 123
	data = ZipCodes.identify(code)
	
	use_redirect_here = false 
	if data
		if use_redirect_here == false 
			url  = URI.escape "/dispensaries/#{data[:state_name]}/#{data[:city]}?zipcode=#{code}"
			redirect url
		else 
			pr[:state] = data[:state_name]
			pr[:city]  = data[:city]
			return erb :'search/search', default_layout
		end
	else 	
		# flash.message = 'No results found for zip code '+code
		# redirect '/'
		redirect '/chat/'+code
	end
end

get '/chat/:code' do
	code = pr[:zipcode] = pr[:code]
	# data = ZipCodes.identify(code)
	pr[:city] = code 
	
	states_for_rooms = {
		nyc: 'New York',
		la: 'California',
		sf: 'California',
		"san diego": 'California',
		chicago: 'Illinois',
		seattle: 'Washington',
		boulder:'Colorado',
		denver: 'Colorado',
		portland: 'Oregon'
	}.hwia
	
	state = states_for_rooms[code] || 'New York'  
	pr[:state] = state

	return erb :'search/search', default_layout
end

get '/dispensaries/:state/?:city?' do
	redirect '/dispensaries/New York' unless AREAS[pr[:state].titleize]
	erb :'search/search', default_layout
end

get '/delivery/:state/?:city?' do
	redirect "/dispensaries/#{pr[:state]}/#{pr[:city]}"
	# redirect '/delivery/New York' unless AREAS[pr[:state].titleize]
	# erb :'search/search', default_layout
end


get '/sitemap.xml' do	
	redirect '/sitemap.txt'
end

get '/sitemap' do	
	redirect '/sitemap.txt'
end


if false && $prod 
	Thread.new {
		while true 
			sleep 6000
			puts "Updating sitemap #{Time.now}"
			$sitemap = Tempfile.new('sitemap.txt')
			File.open($sitemap, 'w') { |file| file.write(zerb :'other/sitemap') }				
		end
	}
end

get '/sitemap.txt' do	
	# ping google to let them know sitemap has updated: 
	# https://www.google.com/ping?sitemap=https://good-weed.com/sitemap.txt 
	headers['Content-Type'] = 'text/plain'
	
	# z.write('hi')
	# z.close
	send_file($sitemap)
	# {a:1}
end

cities = US_STATES_CITIES.values.flatten
cities.each do |city|
	city_route_name = city.gsub(' ','-').downcase 

	get "/#{city_route_name}" do 
		pr[:city]             = city
		pr[:city_route_name]  = city_route_name
		erb :'search/search', default_layout
	end
end

get '/app' do 
	erb :'search/search', default_layout
end

get '/teach' do	
	@teach = true
	erb :'home/home', default_layout
end

get '/influencers' do 
	erb :'influencers/influencers', default_layout
end

get '/ambassadors' do 
	redirect '/influencers'		
end

# if $prod
# 	get '/:channel' do
# 		@channel = pr[:channel]	
# 		@no_container = true
# 		erb :'home/home', default_layout
# 	end
# end

def render_page(page)
	path = "pages/#{page}"
	erb path.to_sym, layout: :layout
end

def sella
	$users.get(email: 'sella.rafaeli@gmail.com')
end

def set_sella_token
	$users.update_id(sella[:_id],{token: guid})
end

get '/html_text' do 
	{text: "<style>
.div {
border:1px solid red;
}
</style>

<div class='div'>
div
</div>

<script>

$('.div').text('bla')

</script>
"}
end