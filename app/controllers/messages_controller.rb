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
        flash[:notice] = {error: ["Seat Already Taken"]}
        format.html { redirect_to chatroom_path }
        format.js { render template: 'chatrooms/chatroom_error.js.erb'} 
      end
    end 
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
      else
        raise Exception.new('Seat Already Taken')
      end
      hash.to_json
    end
end
