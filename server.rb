require 'sinatra'
require 'sinatra/cors'
require 'sinatra/json'
require 'sinatra/reloader' if development?

require 'tilt/erubis'

require_relative 'database_handler'

configure do
  set :erb, :escape_html => true
  set :allow_origin, 'https://www.freecodecamp.org http://127.0.0.1:4567'
  set :allow_methods, 'GET,POST'
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload 'database_handler.rb'
end

before do
  self.storage = DatabaseHandler.new(logger)
end

after do
  storage.disconnect
end

helpers do
  attr_accessor :storage
end

get '/' do
  erb :index, layout: :layout
end

get '/api/shorturl/:num' do |n|
  redirect storage.original n
end

post '/api/shorturl' do
  body = storage.shrink request['url']
  json body
end