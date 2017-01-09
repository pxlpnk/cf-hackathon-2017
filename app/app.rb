require 'sinatra'
require "sinatra/reloader"

post '/webhooks' do
  puts params.inspect
  params.inspect
end

get '/' do
  'Hello'
end
