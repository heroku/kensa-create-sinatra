require 'bundler'
Bundler.require
require 'sinatra/base'
require 'heroku/nav'
require './env'

class App < Sinatra::Base
  use Rack::Session::Cookie, secret: ENV['SSO_SALT']

  helpers do
    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && 
      @auth.credentials == [ENV['HEROKU_USERNAME'], ENV['HEROKU_PASSWORD']]
    end
  end
  
=begin
  # sso landing page
  get "/" do
    #sinatra doesn't keep the cookie during the redirect
    halt 403 unless session[:heroku_sso]
    response.set_cookie('heroku-nav-data', value: session[:heroku_sso])
    haml :index
  end
=end

  # sso sign in
  get "/heroku/resources/:id" do
    pre_token = params[:id] + ':' + ENV['SSO_SALT'] + ':' + params[:timestamp]
    token = Digest::SHA1.hexdigest(pre_token).to_s
    halt 403 if token != params[:token]
    halt 403 if params[:timestamp].to_i < (Time.now - 2*60).to_i

    account = true #User.get(params[:id])
    halt 404 unless account

    session[:heroku_sso] = params['nav-data']
    response.set_cookie('heroku-nav-data', value: params['nav-data'])
    haml :index
  end

  # provision
  post '/heroku/resources' do
    protected!
    #u = User.create()
    #{id: u.id, config: {"MYADDON_URL" => 'http://user.yourapp.com'}}.to_json
    status 201
    {id: 1, config: {"MYADDON_URL" => 'http://user.yourapp.com'}}.to_json
  end

  # deprovision
  delete '/heroku/resources/:id' do
    protected!
    #User.get(params[:id]).destroy
    "ok"
  end

  # plan change
  put '/heroku/resources/:id' do
    protected!
    "ok"
  end
end
