require 'logger'

logger = Logger.new(STDOUT)

class MessagesController < ApplicationController
  def create
    message = Message.new(message_params)

    # :chatroom_id doesn't work as it require
    old_messages = Message.where(chatroom: message.chatroom_id).to_a
    #logger.info("=============== In Create ====================")

    message.user = current_user
    if message.save
      ActionCable.server.broadcast 'messages',
        message: message.content,
        id: message.id,
        user: message.user.username
      head :ok
    end
  end

  def update
    # logger.info("=============== In Update ====================")
    # logger.info("#{params.as_json}")
    message = Message.find(params[:id])
    # logger.info("message:")
    # logger.info("#{message}")
    if message.update(message_params)
      ActionCable.server.broadcast 'messages',
        message: message.content,
        id: message.id,
        user: message.user.username
      head :ok
    end
  end

  def sit
    # logger.info("=============== In sit ====================")
    # logger.info("#{params.as_json}")
    message = Message.find(params[:seat][:message_id])
    user = current_user
    begin
      content = update_hash_sit(message, user, params[:seat][:seat_number])
      if message.update(content: content)
        ActionCable.server.broadcast 'messages',
          message: message.content,
          id: message.id,
          user: message.user.username
        head :ok
      end
    rescue Exception
      respond_to do |format|
        flash[:notice] = {ERROR: ["此位置有人坐了"]}
        format.html { redirect_to chatroom_path }
        format.js { render template: 'messages/game_error.js.erb'} 
      end
    end
  end

  def shuffle
    # logger.info("=============== In shuffle ====================")
    # logger.info("#{params.as_json}")
    message = Message.find(params[:message][:message_id])
    hash = JSON.parse(message.content)
    if is_full_seats?(hash)
      shuffled_roles = hash['roles'].values.shuffle
      shuffled_roles = shuffled_roles.shuffle
      content = update_user_roles(hash, shuffled_roles)
      if message.update(content: content)
        ActionCable.server.broadcast 'messages',
          message: message.content,
          id: message.id,
          user: message.user.username
        head :ok
      end
    else
      respond_to do |format|
        flash[:notice] = {ERROR: ["有空座位 无法发牌"]}
        format.html { redirect_to chatroom_path }
        format.js { render template: 'messages/game_error.js.erb'} 
      end
    end
  end

  def skill
    logger.info("=============== Entering skill use ====================")
    logger.info("#{params.as_json}")
    logger.info("=============== Exiting skill use ====================")
  end

  def start_end
    logger.info("=============== Entering start_end ====================")
    logger.info("#{FIRST_NIGHT_SAVE}")
    logger.info("#{params.as_json}")
    message = Message.find(params[:message][:message_id])
    hash = JSON.parse(message.content)
    user = current_user
    logger.info("=============== Exiting start_end ====================")
  end

  private

    def message_params
      params.require(:message).permit(:content, :chatroom_id)
    end

    def update_hash_sit(message, user, seat)
      hash = JSON.parse(message.content)
      if hash['seats'][seat.to_s]['user'] == 'EMPTY_SEAT_USER'
        hash['seats'][seat.to_s]['user'] = user.username
      elsif hash['seats'][seat.to_s]['user'] == user.username
        hash['seats'][seat.to_s]['user'] = 'EMPTY_SEAT_USER'
        hash['seats'][seat.to_s]['role'] = 'EMPTY_ROLE'
      else
        raise Exception.new('Seat Already Taken')
      end
      hash.to_json
    end

    def update_user_roles(hash, roles)
      if hash['started'] == 'false'
        hash['started'] = 'true'
      else
        hash['started'] = 'false'
      end
      hash.to_json
    end

    def update_game_started(hash)
      room_size = hash[''].to_i
      (1..room_size).each do |i|
        hash['seats'][i.to_s]['role'] = roles[i-1]
      end
      hash.to_json
    end

    def is_full_seats?(hash)
      room_size = hash['room_size'].to_i
      (1..room_size).each do |i|
        if hash['seats'][i.to_s]['user'] == 'EMPTY_SEAT_USER'
          return false
        end
      end
      true
    end
end
