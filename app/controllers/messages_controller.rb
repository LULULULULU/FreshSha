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
    logger.info("=============== In Update ====================")
    logger.info("#{params.as_json}")
    message = Message.find(params[:id])
    logger.info("message:")
    logger.info("#{message}")


    if message.update(message_params)
      ActionCable.server.broadcast 'messages',
        message: message.content,
        id: message.id,
        user: message.user.username
      head :ok
    end
  end

  private

    def message_params
      params.require(:message).permit(:content, :chatroom_id)
    end
end
