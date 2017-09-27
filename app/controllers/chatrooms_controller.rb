class ChatroomsController < ApplicationController

  def index
    @chatroom = Chatroom.new
    @chatrooms = Chatroom.all

    # delete chatroom name room
    # chatrooma = Chatroom.find_by(slug: "new")
    # unless chatrooma.nil?
    #   chatrooma.destroy
    # end
  end

  def new
    if !request.referrer.nil? && request.referrer.split("/").last == "chatrooms"
      flash[:notice] = nil
    end
    @chatroom = Chatroom.new
  end

  def edit
    @chatroom = Chatroom.find_by(slug: params[:slug])
  end

  def create
    # logger.info("=============== In create ====================")
    # logger.info("#{params.as_json}")
    message_content = build_first_message(params[:chatroom])
    # logger.info("#{message_content}")
    if chatroom_params['topic'].strip == "new"
      respond_to do |format|
        flash[:notice] = {ERROR: ["new不是一个合法的名字 GG"]}
        format.html { redirect_to new_chatroom_path }
        format.js { render template: 'chatrooms/chatroom_error.js.erb'} 
      end 
      return
    end
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
          flash[:notice] = {ERROR: ["创建房间失败 GG"]}
          format.html { redirect_to new_chatroom_path }
          format.js { render template: 'chatrooms/chatroom_error.js.erb'} 
        end 
      end
    else
      respond_to do |format|
        flash[:notice] = {ERROR: ["房名空或已存在 GG"]}
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

    hash = JSON.parse(@display_message.last.content)
    # logger.info("=============== In show ====================")
    # logger.info("#{hash['seats']}")
    @seats = build_seats_array(hash['seats'], hash['room_size'].to_i)
    # logger.info("#{@seats.to_s}")
  end

  def destroy
    # logger.info("=============== In destroy ====================")
    # logger.info("#{params.as_json}")
    @chatroom = Chatroom.find_by(slug: params[:slug])
    @chatroom.destroy
 
    redirect_to chatrooms_path
  end

  private

    def chatroom_params
      params.require(:chatroom).permit(:topic)
    end

    def build_seats_array(hash, room_size)
      array = Array.new
      (1..room_size).each do |i|
        seat = Seat.new
        seat.number = i
        seat.user = hash[i.to_s]['user']
        seat.role = hash[i.to_s]['role']
        seat.status = hash[i.to_s]['status']
        array.push(seat)
      end
      array
    end

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
