require 'bundler'
Bundler.require
require 'sinatra/base'
require 'heroku/nav'
require './env'

class App < Sinatra::Base
  use Rack::Session::Cookie, secret: ENV['SSO_SALT']

  @@users = []

  class User
    attr_accessor :plan
    def initialize(plan)
      @plan = plan
    end
  end

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

    def show_request
      STDOUT.puts "Users: #{@@users.inspect}"
      body = request.body.read
      unless body.empty?
        STDOUT.puts "request body:"
        STDOUT.puts JSON.parse(body)
      end
      unless params.empty?
        STDOUT.puts "params: #{params.inspect}"
      end
    end

    def get_user
      @@users[params[:id].to_i] or halt 404, 'user not found'
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
    show_request
    pre_token = params[:id] + ':' + ENV['SSO_SALT'] + ':' + params[:timestamp]
    token = Digest::SHA1.hexdigest(pre_token).to_s
    halt 403 if token != params[:token]
    halt 403 if params[:timestamp].to_i < (Time.now - 2*60).to_i

    account = true #User.get(params[:id])
    halt 404 unless account

    session[:heroku_sso] = params['nav-data']
    response.set_cookie('heroku-nav-data', value: params['nav-data'])

    @user = get_user
    haml :index
  end

  # provision
  post '/heroku/resources' do
    show_request
    protected!
    status 201
    @@users << User.new('test')
    {id: @@users.size+1, config: {"MYADDON_URL" => 'http://user.yourapp.com'}}.to_json
  end

  # deprovision
  delete '/heroku/resources/:id' do
    show_request
    protected!
    @@users.delete(get_user)
    "ok"
  end

  # plan change
  put '/heroku/resources/:id' do
    show_request
    protected!
    user = get_user 
    user.plan = params[:plan]
    "ok"
  end
end
