class MessagesChannel < ApplicationCable::Channel  
  def subscribed
    logger.info('============= In MessagesChannel.subscribed ================')
    logger.info("messages_room_channel_#{params[:chatroom_name]}")
    stream_from "messages_room_channel_#{params[:chatroom_name]}"
  end
end  
