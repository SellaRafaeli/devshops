puts "starting app..."

require 'bundler'

require 'active_support'
require 'active_support/core_ext'
require 'sinatra/reloader' #dev-only

puts "requiring gems..."

Bundler.require

puts "loading dotenv..."
Dotenv.load

$app_name   = 'gutenweed'

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

get '/search' do 
	erb :'search/search', default_layout
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

get '/coding' do	
	@fullstack = true
	erb :'home/home', default_layout
end

get '/fullstack' do	
	@fullstack = true
	erb :'home/home', default_layout
end

get '/about' do	
	erb :'other/landing_page', default_layout
	# erb :'search/search', default_layout
end

get '/' do	
	# erb :'other/landing_page'
	erb :'search/search', default_layout
end

get '/app' do 
	erb :'search/search', default_layout
end

get '/teach' do	
	@teach = true
	erb :'home/home', default_layout
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