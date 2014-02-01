#!/usr/bin/env ruby

# Fitbit Gem Code
##################

require "fitgem"
require "pp"
require "yaml"
require "sinatra"
require "json"

# Load the existing yml config
config = begin
  Fitgem::Client.symbolize_keys(YAML.load(File.open(".fitgem.yml")))
rescue ArgumentError => e
  puts "Could not parse YAML: #{e.message}"
  exit
end

client = Fitgem::Client.new(config[:oauth])

# With the token and secret, we will try to use them
# to reconstitute a usable Fitgem::Client
if config[:oauth][:token] && config[:oauth][:secret]
  begin
    access_token = client.reconnect(config[:oauth][:token], config[:oauth][:secret])
  rescue Exception => e
    puts "Error: Could not reconnect Fitgem::Client due to invalid keys in .fitgem.yml"
    exit
  end
# Without the secret and token, initialize the Fitgem::Client
# and send the user to login and get a verifier token
else
  request_token = client.request_token
  token = request_token.token
  secret = request_token.secret

  puts "Go to http://www.fitbit.com/oauth/authorize?oauth_token=#{token} and then enter the verifier code below"
  verifier = gets.chomp

  begin
    access_token = client.authorize(token, secret, { :oauth_verifier => verifier })
  rescue Exception => e
    puts "Error: Could not authorize Fitgem::Client with supplied oauth verifier"
    exit
  end

  puts 'Verifier is: '+verifier
  puts "Token is:    "+access_token.token
  puts "Secret is:   "+access_token.secret

  user_id = client.user_info['user']['encodedId']
  puts "Current User is: "+user_id

  config[:oauth].merge!(:token => access_token.token, :secret => access_token.secret, :user_id => user_id)

  # Write the whole oauth token set back to the config file
  File.open(".fitgem.yml", "w") {|f| f.write(config.to_yaml) }
end

# END Fitbit Gem stuff =================================


# Real code
############

get "/" do
	# assign a variable to the data from Fitbit
	@raw = client.user_info['user']

	# These two lines convert the data to JSON and back to a hash
		# unnecessary in this case but probably useful to know later
	# @data = @raw.to_json
	# @parsed = JSON.parse(@raw)

	# method to format the Fitbit data into nice lines
	@pretty = JSON.pretty_generate(@raw)
	
	# link up the view
	erb :index
end



# other basic Sinatra routes (from tutorial):
#######

# get "/hello/:name" do
# 	"Hello there, #{params[:name]}."
# end

# get "/more/*" do  
#   params[:splat]  
# end