require 'couchrest_model'
require 'net/http'
require 'json'
require 'yaml'

class GameInformationGateway 

  def download(appid)

    url = "http://store.steampowered.com/api/appdetails/?appids=#{appid}"
    resp = Net::HTTP.get(URI.parse(url))

    resp
  end 
end
  
class Game < CouchRest::Model::Base

  property :source,	String

  timestamps!

  design do
    view :by_name
  end

end

class SteamGame < Game

  SCHEMA_KEYS = ["name", "steam_appid", "required_age", "is_free",
    "about_the_game", "supported_languages", "header_image", "website", "platforms",
    "developers", "publishers", "price_overview", "background", 
    "platforms", "metacritic", "categories", "genres", "recommendations",
    "release_date", "movies"]

  SCHEMA_KEYS_SPECIAL = {"type": "steam_type"}  

  self.class_eval do
    SCHEMA_KEYS.concat(SCHEMA_KEYS_SPECIAL.values).each do |key|
      property key.to_sym
    end
  end

  def initialize(opts = {})
    super()
    SCHEMA_KEYS.each do |key|
      send("#{key}=", opts[key])
    end
    SCHEMA_KEYS_SPECIAL.each do |k, v|
      send("#{v}=", opts[k.to_s])
    end
    send("source=", "steam")
  end
end

def download_game_info
  info_gateway = GameInformationGateway.new
  error_log = File.open("error.log", "w")
  failed_app_ids = File.open("failed.log", "w")
  File.open("allappids").each do |id|
    appid = id.strip
    begin
      game_data_raw = JSON.parse(info_gateway.download(appid))
      get_game_info(game_data_raw, appid, error_log, failed_app_ids)
    rescue Exception => e
      error_log.write("Exception: Failed to download app data for appid: #{appid}, with exception: #{exception}\n")
      failed_app_ids.write("#{appid}\n")
    end
  end
  error_log.close()
  failed_app_ids.close()
end

def get_game_info(game_data_raw, appid, log, failed_log)
  if game_data_raw[appid.to_s]["success"]
    game_data = game_data_raw[appid.to_s]["data"]
    game = SteamGame.new(game_data)
    game.save
  else
    log.write("No data available for appid: #{appid}\n")
    failed_log.write("#{appid}\n")
  end
end




