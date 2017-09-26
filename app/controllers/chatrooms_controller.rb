class ChatroomsController < ApplicationController

  def index
    @chatroom = Chatroom.new
    @chatrooms = Chatroom.all
  end

  def new
    if request.referrer.split("/").last == "chatrooms"
      flash[:notice] = nil
    end
    @chatroom = Chatroom.new
  end

  def edit
    @chatroom = Chatroom.find_by(slug: params[:slug])
  end

  def create
    logger.info("=============== In create ====================")
    logger.info("#{params.as_json}")

    message_content = build_first_message(params[:chatroom])
    logger.info("#{message_content}")

    @chatroom = Chatroom.new(chatroom_params)
    if @chatroom.save
      user = User.find_by(:id => 1)
      message = Message.new(:chatroom_id => @chatroom.id, :user => user, :content => message_content)
      if message.save
        respond_to do |format|
          format.html { redirect_to @chatroom }
         format.js
        end
      else
        respond_to do |format|
          flash[:notice] = {error: ["creating room failed"]}
          format.html { redirect_to new_chatroom_path }
          format.js { render template: 'chatrooms/chatroom_error.js.erb'} 
        end 
      end
    else
      respond_to do |format|
        flash[:notice] = {error: ["a chatroom with this topic already exists"]}
        format.html { redirect_to new_chatroom_path }
        format.js { render template: 'chatrooms/chatroom_error.js.erb'} 
      end
    end
  end

  def update
    chatroom = Chatroom.find_by(slug: params[:slug])
    chatroom.update(chatroom_params)
    redirect_to chatroom
  end

  def show
    @chatroom = Chatroom.find_by(slug: params[:slug])
    @chatroom_message = @chatroom.messages
    @display_message = [@chatroom.messages.order('created_at').last]
    @current_user = current_user
    @message = Message.new
  end

  def destroy
    logger.info("=============== In destroy ====================")
    logger.info("#{params.as_json}")
    @chatroom = Chatroom.find_by(slug: params[:slug])
    @chatroom.destroy
 
    redirect_to chatrooms_path
  end

  private

    def chatroom_params
      params.require(:chatroom).permit(:topic)
    end

    # { "topic"=>" asdf", "cure_rules"=>"FirstNightSave", "poison_rule"=>"CannotUseCurePoisonSameNight", "guard_rule"=>"GuardAndCuredIsDead", "thief_rule"=>"MustPickWerewolf", 
    #   "seer"=>"1", "witch"=>"1", "hunter"=>"0", "defender"=>"0", "elder"=>"0", "thief"=>"0", "villager"=>"2", "whitewolf"=>"0", "werewolf"=>"2"}
    #
    #" { \"1\":{\"user\":\"xiao\", \"role\":\"seer\", \"status\":\"dead\"}, \"2\":{\"user\":\"王立凡\", \"role\":\"werewolf\"}, \"cureRule\":\"FirstNightSave\", \"turn\":\"98977\"}"
    def build_first_message(params)
      seer = params[:seer].to_i
      witch = params[:witch].to_i
      hunter = params[:hunter].to_i
      defender = params[:defender].to_i
      thief = params[:thief].to_i
      elder = params[:elder].to_i
      villager = params[:villager].to_i
      whitewolf = params[:whitewolf].to_i
      werewolf = params[:werewolf].to_i

      room_size = seer + witch + hunter + defender + thief + elder + villager + whitewolf + werewolf
      if thief >= 1
        room_size -= 2
      end

      roles = Array.new
      if seer >= 1
        roles.push("seer")
      end

      if witch >= 1
        roles.push("witch")
      end

      if hunter >= 1
        roles.push("hunter")
      end

      if defender >= 1
        roles.push("defender")
      end

      if thief >= 1
        roles.push("thief")
      end

      if elder >= 1
        roles.push("elder")
      end

      if whitewolf >= 1
        roles.push("whitewolf")
      end

      (1..villager).each do |i|
        roles.push("villager")
      end

      (1..werewolf).each do |i|
        roles.push("werewolf")
      end

      string = "{\"cure_rules\":\"#{params[:cure_rules]}\", \"poison_rule\":\"#{params[:poison_rule]}\", \"guard_rule\":\"#{params[:guard_rule]}\", \"thief_rule\":\"#{params[:thief_rule]}\", \"room_size\":\"#{room_size}\", "
      string = string + " \"seats\":{ "
      (1..room_size).each do |i|
        string = string + "\"#{i}\":{\"user\":\"EMPTY_SEAT_USER\", \"role\":\"EMPTY_ROLE\", \"status\":\"NORMAL\"},"
      end
      string = string[0..-2] #remove last ,
      string = string + "}, \"roles\":{"

      roles.each_with_index { |item, index|
        string = string + " \"#{index}\": \"#{item}\","
      }
      string = string[0..-2] #remove last ,
      string = string + "} }"
      string
    end
end
