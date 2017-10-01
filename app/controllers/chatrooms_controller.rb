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
    begin
      message_content = build_first_message(params[:chatroom])
      # logger.info("#{message_content}")
      if chatroom_params['topic'].strip == "new"
        raise ChatroomsHelper::ChatroomCreateError.new("new不是一个合法的名字 GG")
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
          raise ChatroomsHelper::ChatroomCreateError.new("创建房间失败 GG")
        end
      else
        raise ChatroomsHelper::ChatroomCreateError.new("房名空或已存在 GG")
      end
    rescue ChatroomsHelper::ChatroomCreateError => error
      respond_to do |format|
        flash[:notice] = {ERROR: ["#{error.message}"]}
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

    begin
      @hash = JSON.parse(@display_message.last.content)
      @seats = build_seats_array(@hash['seats'], @hash['room_size'].to_i)
    rescue JSON::ParserError
      @hash = {}
      @seats = []
    end
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

      if room_size <= 0
        raise ChatroomsHelper::ChatroomCreateError.new("至少要有一个角色")
      end
      if thief >= 1
        room_size -= 2
      end

      roles = Array.new
      if seer >= 1
        roles.push(SEER)
      end

      if witch >= 1
        roles.push(WITCH)
      end

      if hunter >= 1
        roles.push(HUNTER)
      end

      if defender >= 1
        roles.push(DEFENDER)
      end

      if thief >= 1
        roles.push(THIEF)
      end

      if elder >= 1
        roles.push(ELDER)
      end

      if whitewolf >= 1
        roles.push(WHITEWOLF)
      end

      (1..villager).each do |i|
        roles.push(WHITEWOLF)
      end

      (1..werewolf).each do |i|
        roles.push(WEREWOLF)
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
      string = string + "}, \"started\": \"false\", \"master_user\": \"EMPTY_SEAT_USER\", \"turn\": \"EMPTY_ROLE\"}"
      string
    end
end
