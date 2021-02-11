require 'erb'
require 'logger'
require 'mail'
require 'sanitize'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/cors'
require 'sinatra/r18n'

require './helpers/application_helper'

class Forbidden < StandardError
  def http_status; 403 end
end

class NotFound < StandardError
  def http_status; 404 end
end

class App < Sinatra::Base
  register Sinatra::R18n
  register Sinatra::Cors
  set :root, __dir__
  set :allow_origin, "#{ENV['ALLOW_LIST']}"
  set :allow_methods, "GET,HEAD,POST"
  set :allow_headers, "content-type"
  helpers ApplicationHelper
  log = Logger.new('logs/log.txt', 'monthly')

  get '/' do
    redirect to '/de'
  end

  get '/:locale' do
    erb :index
  end

  post '/send' do
    log.info "Request hit /send"
    name = Sanitize.fragment(params[:name], Sanitize::Config::RELAXED)

    Thread.abort_on_exception = true
    Thread.new  {
      log.info "Starting thread to write email"
      email_body = erb :mailer, locals: {name: name}
      mail = Mail.new do
        from    "#{ENV['EMAIL_FROM']}"
        to      "#{ENV['EMAIL_TO']}"
        subject "[#{ENV['APP_NAME']}] You got mail!"
        body    email_body
      end
      mail.delivery_method :sendmail
      mail.deliver!
      log.info "Done emailing"
    }

    redirect back
  end

  error 403 do
    'Error 403 Forbidden'
  end

  error 404 do
    'Error 404 Not Found'
  end
end
