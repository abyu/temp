require 'couchrest_model'
require 'net/http'
require 'json'
require 'yaml'

class SteamGameInfoSchema
  def keys_to_include 
    ["type", "name", "steam_appid", "required_age", "is_free",
    "about_the_game", "supported_languages", "header_image", "website", "platforms", "developers", "publishers", "price_overview", "packages", 
    "platforms", "metacritic", "categories", "genres", "recommendations",
    "release_date"]
  end

  def parse(json_data)
    json_data.reject {|k,v| !keys_to_include.include?(k)}
  end
end

class GameInformationGateway 

  def download(appid)

    url = "http://store.steampowered.com/api/appdetails/?appids=#{appid}"
    resp = Net::HTTP.get(URI.parse(url))

    resp
  end
end
  
class Game < CouchRest::Model::Base

  property :name,	String
  property :source,	String
  property :data, 	String

  timestamps!

end

File.open("allappids").each do |id|
  appid = id.strip
  begin
    game_data_raw = JSON.parse(GameInformationGateway.new.download(appid))
    steam_game_info_parser = SteamGameInfoSchema.new
    if game_data_raw[appid.to_s]["success"]
      game_data = game_data_raw[appid.to_s]["data"]
      game = Game.new(:name => game_data["name"], :source => "steam", :data => steam_game_info_parser.parse(game_data))
      game.save

    else
      p "no success"
    end    
  rescue Exception => e
    p e
  end

end

