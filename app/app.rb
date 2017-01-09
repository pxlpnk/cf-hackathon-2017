require 'sinatra'
require "sinatra/reloader"
require 'json'
require 'fluent-logger'

def fluent_tag
  "contentful.webhook"
end

def fluent_host
  ENV["FLUENT_HOST"] || "localhost"
end

def fluent_port
  ENV["FLUENT_PORT"] || "localhost"
end

post '/webhooks' do
  body = parse_payload_body
  record = build_record(body)
  log_record(record)
end

get '/' do
  cowboy
end

def cowboy
<<-ASCII
<pre>
            ___
         __|___|__
          ('o_o')
          _\~-~/_    ______.
         //\__/\ \ ~(_]---'
        / )O  O( .\/_)
        \ \    / \_/
        )/_|  |_\
       // /(\/)\ \
       /_/      \_\
      (_||      ||_)
        \| |__| |/
         | |  | |
         | |  | |
         |_|  |_|
         /_\  /_\

  Hello Stranger
</pre>
  ASCII
end

def parse_payload_body
  request.body.rewind
  raw_body = request.body.read
  body = JSON.parse(raw_body)
  body
end

def build_record(body)
  {
   topic: request.env["HTTP_X_CONTENTFUL_TOPIC"],
   user: extract_user(body),
   version: body["sys"]["version"] || body["sys"]["revision"] || -1,
   updated_at: body["sys"]["updatedAt"],
   raw_payload: body.to_json
  }
end

def extract_user(body)
  body["sys"]["updatedBy"] && body["sys"]["updatedBy"]["sys"]["id"]
end

def log_record(record)
  Fluent::Logger::FluentLogger.open(nil, :host=>fluent_host, :port=>fluent_port)
  Fluent::Logger.post(fluent_tag, record)
end
