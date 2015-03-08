$:.unshift File.expand_path('../lib', __FILE__)

require 'sinatra'
require 'yaml'
require 'httparty'
require 'json'
require 'slim'

QUERY_BASE = "http://api.giphy.com/v1/gifs/search?q="
API_KEY = "&limit=50&api_key=dc6zaTOxFJmzC"

class UnoServer 
  attr_reader :deck, :pool, :hands, :number_of_hands
  MAX_HANDS = 5
  def initialize 
    @hands = Array.new
    @number_of_hands = 0
    @pool = Array.new
    @deck = Array.new 
  end
 
  def join_game player_name 
    unless @hands.size < MAX_HANDS
      puts "Can't join"
      return false
    end
    print "Player #{player_name} is joining the game"
    player = { 
        name: player_name, 
        cards: [] 
    } 
    @hands.push player 
    puts "No players: ", @hands.size
    true
  end
 
  def deal 
    return false unless @hands.size > 0
    query =  QUERY_BASE + "cats" + API_KEY
    res = HTTParty.get(query)
    parse = JSON.parse(res.body)
    @deck = parse['data']
    @pool = deck.shuffle 
    @hands.each {|player| player[:cards] = @pool.pop(5)} 
    true
  end
 
  def get_cards player_name 
    cards = 0
    puts "In get cards, the name is #{player_name}"
    @hands.each do |player| 
    
      if player[:name] == player_name 
        cards = player[:cards].dup 
        break
      end
    end
    cards 
  end
 
end

uno = UnoServer.new


  get '/' do
  	slim :home
  end

  post '/form' do
  	p = params[:search_terms].split(' ').join('+')
    query =  QUERY_BASE + "#{p}" + API_KEY
    res = HTTParty.get(query)
    @result = JSON.parse(res.body)
  
    slim :result
  end

  get '/cards' do
    puts params
    return_message = {} 
    if params.has_key?('name') 
      @@cards = uno.get_cards(params['name']) 
      if @@cards.class == Array
        return_message[:status] == 'success'
        return_message[:cards] = @@cards 
      else
        return_message[:status] = 'sorry - it appears you are not part of the game'
        return_message[:cards] = [] 
      end
    end
    
    slim :view_cards
  end
 
  post '/join' do
    return_message = {} 
    jdata = params['player_name']
    if jdata && uno.join_game(jdata) 
      return_message[:status] = 'welcome'
      @@player_name = jdata
    else
      return_message[:status] = 'sorry - game not accepting new players'
      redirect '/no_more'
    end
    

    slim :game 
  end
 
  post '/deal' do
    return_message = {} 
    if uno.deal 
      return_message[:status] = 'success'
    else
      return_message[:status] = 'fail'
    end
    redirect "/cards?name=#{@@player_name}" 
  end

  get '/no_more' do 
    slim :no_more
  end