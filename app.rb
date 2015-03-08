$:.unshift File.expand_path('../lib', __FILE__)

require 'sinatra'
require 'yaml'
require 'httparty'
require 'json'
require 'slim'
require 'cgi'

QUERY_BASE = "http://api.giphy.com/v1/stickers/trending?api_key=dc6zaTOxFJmzC"
API_KEY = "api_key=dc6zaTOxFJmzC"

class UnoServer 
  attr_reader :deck, :pool, :hands, :number_of_hands
  MAX_HANDS = 3
  def initialize 
    @hands = []
    @number_of_hands = 0
    @pool = []
    @deck = [] 
    @chosen_cards = []
  end
 
  def join_game player_name 
    unless @hands.size < MAX_HANDS
      create_game
      return false
    end
   
    player = { 
        name: player_name, 
        cards: [],
        is_judge: false 
    } 
    @hands.push player 
    true
  end
 
  def deal 
    return false unless @hands.size > 0
    query =  QUERY_BASE
    res = HTTParty.get(query)
    parse = JSON.parse(res.body)
    
    @deck = parse['data']
    
    @pool = @deck.shuffle 
    @hands.each { |player| player[:cards] = @pool.pop(5) }
    
    true
  end
 
  def get_cards player_name 
    cards = 0
    
    @hands.each do |player|   
      puts player
      if player[:is_judge]
        return "judge"
      elsif player[:name] == player_name 
        cards = player[:cards].dup 
        break
      
      end
    end
    cards 
  end
 
  def create_game
    judge = Random.new.rand(0...MAX_HANDS)
    hands[judge][:is_judge] = true
    puts "Judge est #{judge}"
    deal
  end
 
  def collect_the_cards(player, card_no)

    puts "In collect_the_cards"
    @hands.each do |player|
      if player[:name] == player
        @chosen_cards << {
          player_name: player,
          card: player[:cards][card_no]
          }
      end
    end
    puts @chosen_cards.size
  end

  def time_for_decision
    puts "Time for decision"
    puts @chosen_cards.size
    if @chosen_cards.size == MAX_HANDS - 1
      true
    else
      false
    end
  end

  def get_chosen_cards
    @chosen_cards
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

  post '/cards' do
    puts params
    @@player_name = params['player_name']
    
    return_message = {} 
    if params.has_key?('player_name') 
      @@cards = uno.get_cards(params['player_name']) 
      if @@cards.class == Array
        return_message[:status] == 'success'
        return_message[:cards] = @@cards 
      elsif @@cards == 'judge'
          redirect '/judge'
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

  get '/choose_card' do
    chosen_card = CGI.unescapeHTML(params['card'])
    uno.collect_the_cards(@@player_name, chosen_card)

    slim :wait_for_decision
  end

  get '/no_more' do 
    slim :no_more
  end

  get '/judge_data' do
    puts "Called judge_data"
    if uno.time_for_decision
      @@data = get_chosen_cards
    else
      status 404
    end
    
  end

  get '/judge' do
    
    slim :judge

  end