require 'sinatra'
require "sinatra/reloader"
require 'json'
require 'fluent-logger'

require 'contentful'
require 'contentful/management'

def fluent_tag
  "contentful.webhook"
end

def fluent_host
  ENV["FLUENT_HOST"] || "localhost"
end

def fluent_port
  ENV["FLUENT_PORT"] || "24224"
end



require 'dotenv'
Dotenv.load

def client
  @client ||= Contentful::Management::Client.new(ENV["CMA_TOKEN"])
end

def space
  @space ||= client.spaces.find(ENV["SPACE_KEY"])
end

def cf_content_type
  @cf_content_type ||= space.content_types.find(ENV["CONTENT_TYPE"])
end

post '/webhooks' do
  body = parse_payload_body
  record = build_record(body)
  log_record(record)
  create_entry(record)
  'Cowboy!!'
end

get '/' do
  cowboy
end

get '/auditlog' do
  make_table
end

def make_table
  table = entries.map do |entry|
    tabelize_entry(entry)
  end.join('')

  "<table>
<tr>
<th>Updated At</th>
<th>space id</th>
<th>entry id</th>
<th>user</th>
<th>topic</th>
</tr>

#{table}</table>"
end


def tabelize_entry(entry)
  "<tr>
<td>
#{entry.fields[:updatedAt]}
</td>
<td>
#{entry.fields[:spaceId]}
</td>
<td>
#{entry.fields[:entryId]}
</td>
<td>
#{entry.fields[:user]}
</td>
<td>
#{entry.fields[:topic]}
</td>
</tr>"
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
   updatedAt: body["sys"]["updatedAt"],
   spaceId: extract_space(body),
   entryId: extract_entry(body),
   rawPayload: body.to_json.to_s
  }
end

def extract_user(body)
  body["sys"]["updatedBy"] && body["sys"]["updatedBy"]["sys"]["id"]
end

def extract_entry(body)
  body["sys"]["id"]
end

def extract_space(body)
  body["sys"]["space"] && body["sys"]["space"]["sys"]["id"]
end

def log_record(record)
  Fluent::Logger::FluentLogger.open(nil, :host=>fluent_host, :port=>fluent_port)
  Fluent::Logger.post(fluent_tag, record)
end

def create_entry(record)
  entry = cf_content_type.entries.create(record)
  entry.publish
end

def cda_client
  Contentful::Client.new(
                         access_token: ENV["CDA_TOKEN"],
                         space: ENV["SPACE_KEY"]
                        )
end

def entries
  cda_client.entries(content_type: ENV["CONTENT_TYPE"])
end
