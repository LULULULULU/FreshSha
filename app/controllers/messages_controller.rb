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
    rescue MessagesHelper::MessageError
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
      # logger.info("1: #{shuffled_roles}")
      shuffled_roles = shuffled_roles.shuffle
      # logger.info("2: #{shuffled_roles}")
      content = update_user_roles(hash, shuffled_roles)
      # logger.info("=============== exiting shuffle ====================")
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
    # logger.info("=============== Entering skill use ====================")
    # logger.info("#{params.as_json}")
    message = Message.find(params[:skill][:message_id])
    hash = JSON.parse(message.content)
    parameters = params[:skill]
    user_name = params[:skill][:user_name]
    caster = params[:skill][:caster]
    result = check_valid_skill_casting?(hash, user_name, caster)
    error = ''

    case result
    when 200
      # logger.info("^_^ ^_^ ^_^ ^_^ ^_^ ^_^ ^_^ ^_^ ^_^ ^_^ ^_^ ")
      # logger.info("^_^ ^_^ ^_^   YOU CAN USE SKILL  ^_^ ^_^ ^_^ ^_^ ")
      # logger.info("^_^ ^_^ ^_^ ^_^ ^_^ ^_^ ^_^ ^_^ ^_^ ^_^ ^_^ ")

      begin
        case caster
        when SEER
          seer_skill(hash, parameters)
        when WITCH
          witch_skill(hash, parameters)
        when WOLF
          wolf_skill(hash, parameters)
          update_witch_save_info(hash)
        when DEFENDER
          defender_skill(hash, parameters)
        else
          raise MessagesHelper::SkillUseError.new("错误技能使用者 #{caster}")
        end

        content = update_game_turn(hash)
        if message.update(content: content)
          ActionCable.server.broadcast 'messages',
            message: message.content,
            id: message.id,
            user: message.user.username
          head :ok
        end
      rescue MessagesHelper::SkillUseError => error
        respond_to do |format|
          flash[:notice] = {ERROR: ["#{error.message}"]}
          format.html { redirect_to chatroom_path }
          format.js { render template: 'messages/game_error.js.erb'}
        end
      end
      return

    when 400
      error = "游戏还未开始"
    when 401
      error = "角色不对 你是#{caster}"
    when 402
      error = "轮次不对 当前是#{hash['turn']}轮次"
    when 502
      error = "用户不在房间内"
    else
      error = "未知错误 GG"
    end
    respond_to do |format|
      flash[:notice] = {ERROR: [error]}
      format.html { redirect_to chatroom_path }
      format.js { render template: 'messages/game_error.js.erb'}
    end
    # logger.info("=============== Exiting skill use ====================")
  end

  def start_end
    # logger.info("=============== Entering start_end ====================")
    # logger.info("#{params.as_json}")
    message = Message.find(params[:message][:message_id])
    hash = JSON.parse(message.content)
    user = current_user
    content = update_game_started(hash, user)
    if message.update(content: content)
      ActionCable.server.broadcast 'messages',
        message: message.content,
        id: message.id,
        user: message.user.username
      head :ok
    end
    # logger.info("=============== Exiting start_end ====================")
  end




  private
  # ====================================================================================
  # ====================================================================================
  # ==================== Skill Methods ========================
  # ====================================================================================
  # ====================================================================================

    def seer_skill(hash, params)
      night = hash['night']
      turn = hash['turn']

      # Make sure seer use right skill at the right seer turn
      if turn == SEER_CHECK_TURN && !params.include?(SEER_CHECK)
        raise MessagesHelper::SkillUseError.new("预言家请先验人")
      elsif turn == SEER_END_TURN && !params.include?(SEER_END)
        raise MessagesHelper::SkillUseError.new("预言家请结束")
      end

      if params.include?(SEER_CHECK)
        seer_check_seat = params[SEER_CHECK]
        hash['night_actions'] ||= {}  # make sure hash['night_action'] not nil
        night_hash = hash['night_actions'][night] ||= {} # make sure hash['night_action'][night] not nil
        night_hash[SEER_CHECK] = seer_check_seat

        # Set display message for seer check
        if hash['seats'].include?(seer_check_seat)
          check_role = hash['seats'][seer_check_seat]['role']
          if check_role == 'EMPTY_ROLE'
            raise MessagesHelper::SkillUseError.new("#{seer_check_seat}号身份错误: #{check_role}")
          elsif check_role == WEREWOLF || check_role == WHITEWOLF
            hash['seer_check_display'] = "#{seer_check_seat}号身份是: 狼人"
          else
            hash['seer_check_display'] = "#{seer_check_seat}号身份是: 好人"
          end
        else
          raise MessagesHelper::SkillUseError.new("#{seer_check_seat}号座位不存在")
        end

      elsif params.include?(SEER_END)
        night_hash = hash['night_actions'][night] ||= {} # make sure hash['night_action'][night] not nil
        night_hash[SEER_END] = 'true'
      else
        raise MessagesHelper::SkillUseError.new("预言家技能发生错误")
      end
      hash.to_json
    end

    def witch_skill(hash, params)
      night = hash['night']
      witch_name = params['user_name']
      hash['night_actions'] ||= {}  # make sure hash['night_action'] not nil
      night_hash = hash['night_actions'][night] ||= {} # make sure hash['night_action'][night] not nil
      victim_seat = night_hash[WOLF_KILL]

      if victim_seat == 'not kill'
        victim_name = nil
      else
        victim_name = hash['seats'][victim_seat]['user']
      end
      use_save = false

      if params.include?(WITCH_KILL) && params.include?(WITCH_SAVE)
        if params[WITCH_SAVE] == 'save'
          # if still have drug
          if hash['drug_used'] == 'true'
            raise MessagesHelper::SkillUseError.new("解药已经使用")
          end

          # if save, check if no victim
          if victim_name.nil?
            raise MessagesHelper::SkillUseError.new("没有人被杀 无法使用解药")
          end

          # check if victim is witch
          if victim_name == witch_name
            if hash[CURE_RULES] == FIRST_NIGHT_SAVE
              if night != '1'
                raise MessagesHelper::SkillUseError.new("仅第一夜可以自救")
              end
            elsif hash[CURE_RULES] == NOT_SELF_SAVE
              raise MessagesHelper::SkillUseError.new("不可以自救")
            elsif hash[CURE_RULES] == CAN_SELF_SAVE
              use_save = true
            else
              raise MessagesHelper::SkillUseError.new("救人规则错误: #{hash[CURE_RULES]}")
            end
          end

          # if self-save, none-dead and has-drug checks all passed
          # update night_hash, hash['drug_used'] flag and use_save local flag
          night_hash[WITCH_SAVE] = 'true'
          hash['drug_used'] = 'true'
          use_save = true
        elsif params[WITCH_SAVE] == 'not save'
          night_hash[WITCH_SAVE] = 'false'
          use_save = false
        else
          raise MessagesHelper::SkillUseError.new("救人错误: #{params[WITCH_SAVE]}")
        end # END of SAVE logic


        if params[WITCH_KILL] == 'not kill'
          night_hash[WITCH_KILL] = 'not kill'
        else
          poison_kill_seat = params[WITCH_KILL]
          # make sure killing a legit seat
          unless hash['seats'].include?(poison_kill_seat)
            raise MessagesHelper::SkillUseError.new("下毒位置错误: #{poison_kill_seat}")
          end

          # if still have poison
          if hash['poison_used'] == 'true'
            raise MessagesHelper::SkillUseError.new("毒药已经使用")
          end

          # if CURE_POISON_TOGETHER
          if use_save && hash[POISON_RULE] == NOT_CURE_POISON_TOGETHER
            raise MessagesHelper::SkillUseError.new("不可以解药毒药同时用")
          end

          # if position check, have-poison check and CURE_POISON_TOGETHER check all passed
          # update night_hash and hash['poison_used']
          night_hash[WITCH_KILL] = poison_kill_seat
          hash['poison_used'] = 'true'
        end # END of KILL logic
      else
        raise MessagesHelper::SkillUseError.new("女巫技能发生错误")
      end
      hash.to_json
    end

    def wolf_skill(hash, params)
      night = hash['night']
      if params.include?(WOLF_KILL)
        hash['night_actions'] ||= {}  # make sure hash['night_action'] not nil
        night_hash = hash['night_actions'][night] ||= {} # make sure hash['night_action'][night] not nil
        night_hash[WOLF_KILL] = params[WOLF_KILL]
      else
        raise MessagesHelper::SkillUseError.new("狼人技能发生错误")
      end
      hash.to_json
    end

    def defender_skill(hash, params)
      night = hash['night']
      if params.include?(DEFENDER_GUARD)
        tonight_guard = params[DEFENDER_GUARD]
        hash['night_actions'] ||= {}  # make sure hash['night_action'] not nil
        night_hash = hash['night_actions'][night] ||= {} # make sure hash['night_action'][night] not nil

        previous_night = night.to_i - 1
        if previous_night >= 1
          last_night_guard = hash['night_actions'][previous_night.to_s][DEFENDER_GUARD]
          if last_night_guard != 'not guard' && last_night_guard == tonight_guard
            raise MessagesHelper::SkillUseError.new("不能两晚守护同一玩家: #{last_night_guard}")
          end
        end

        night_hash[DEFENDER_GUARD] = tonight_guard
      else
        raise MessagesHelper::SkillUseError.new("守卫技能发生错误")
      end
      hash.to_json
    end

  # ====================================================================================
  # ====================================================================================
  # ==================== Private Methods ========================
  # ====================================================================================
  # ====================================================================================


    def message_params
      params.require(:message).permit(:content, :chatroom_id)
    end

    # toggle for user SIT and STAND actions
    def update_hash_sit(message, user, seat)
      hash = JSON.parse(message.content)
      room_size = hash['room_size'].to_i

      if hash['seats'][seat.to_s]['user'] == 'EMPTY_SEAT_USER'
        # If empty, stand up and sit
        (1..room_size).each do |i|
          if hash['seats'][i.to_s]['user'] == user.username
            hash['seats'][i.to_s]['user'] = 'EMPTY_SEAT_USER'
            hash['seats'][i.to_s]['role'] = 'EMPTY_ROLE'
          end
        end
        hash['seats'][seat.to_s]['user'] = user.username
      elsif hash['seats'][seat.to_s]['user'] == user.username
        # if sit here, stand up
        hash['seats'][seat.to_s]['user'] = 'EMPTY_SEAT_USER'
        hash['seats'][seat.to_s]['role'] = 'EMPTY_ROLE'
      else
        # if seat by other, exception
        raise MessagesHelper::MessageError.new('Seat Already Taken')
      end
      hash.to_json
    end

    # toggle the game to be started or ended
    def update_game_started(hash, user)
      if hash['started'] == 'false'
        hash['started'] = 'true'
        hash['master_user'] = user.username
        start_game_turns(hash)
        hash['seer_check_display'] = '此处显示验证结果'
        hash['witch_save_display'] = '此处显示刀型'
        hash['night'] = '1'
      else
        hash['started'] = 'false'
        hash['master_user'] = 'EMPTY_SEAT_USER'
        hash['turn'] = 'EMPTY_ROLE'
        hash['turn_display'] = '游戏尚未开始'
        hash['seer_check_display'] = '游戏尚未开始'
        hash['witch_save_display'] = '游戏尚未开始'
        hash['night'] = '0'
      end
      hash['night_actions'] = {}
      hash.delete('drug_used')
      hash.delete('poison_used')
      hash.delete('last_night_info_display')

      hash.to_json
    end

    # set the game start turn and turn_display
    def start_game_turns(hash)
      all_roles = hash['roles'].values
      if all_roles.include?(THIEF)
        hash['turn'] = THIEF
        hash['turn_display'] = GAME_TURN_DISPLAY_MAP[THIEF]

      elsif all_roles.include?(DEFENDER)
        hash['turn'] = DEFENDER
        hash['turn_display'] = GAME_TURN_DISPLAY_MAP[DEFENDER]

      elsif all_roles.include?(SEER)
        hash['turn'] = SEER_CHECK_TURN
        hash['turn_display'] = GAME_TURN_DISPLAY_MAP[SEER_CHECK_TURN]

      elsif all_roles.include?(WHITEWOLF) || all_roles.include?(WEREWOLF)
        hash['turn'] = WOLF
        hash['turn_display'] = GAME_TURN_DISPLAY_MAP[WOLF]

      elsif all_roles.include?(WITCH)
        hash['turn'] = WITCH
        hash['turn_display'] = GAME_TURN_DISPLAY_MAP[WITCH]

      else
        hash['turn'] = DAY_TIME
        hash['turn_display'] = GAME_TURN_DISPLAY_MAP[DAY_TIME]
      end
      hash
    end

    # update user on 1..n seat with the order of roles array
    def update_user_roles(hash, roles)
      room_size = hash['room_size'].to_i
      (1..room_size).each do |i|
        hash['seats'][i.to_s]['role'] = roles[i-1]
      end
      hash.to_json
    end

    # Check is all seats have a user sitting on it
    def is_full_seats?(hash)
      room_size = hash['room_size'].to_i
      (1..room_size).each do |i|
        if hash['seats'][i.to_s]['user'] == 'EMPTY_SEAT_USER'
          return false
        end
      end
      true
    end

    # Check skill can be casted
    # @return 200, everything ok, can be casted
    # @return 400, game didn't start
    # @return 401, user is not caster
    # @return 402, not user/caster's turn
    # @return 500, user not found in room
    def check_valid_skill_casting?(hash, user_name, caster)
      if hash['started'] == 'false'
        return 400
      end
      room_size = hash['room_size'].to_i
      turn = hash['turn']
      (1..room_size).each do |i|
        seat = hash['seats'][i.to_s]
        if seat['user'] == user_name
          # Find user seat
          unless seat['role'].include?(caster)
            return 401 # user is not caster
          end

          if caster == SEER
            if turn != SEER_CHECK_TURN && turn != SEER_END_TURN
              return 402 # not SEER turn
            end
          else
            unless caster == turn
              return 402 # not other [witch, defender, wolf, witch] turn
            end
          end
          return 200
        end
      end # end loop

      return 500
    end

    # Update game turn, decide what value in GAME_TURN need to be set in hash['turn']
    def update_game_turn(hash)
      room_included_turns = []
      all_roles = hash['roles'].values
      if all_roles.include?(THIEF) then room_included_turns.push(THIEF) end
      if all_roles.include?(DEFENDER) then room_included_turns.push(DEFENDER) end
      if all_roles.include?(SEER)
        room_included_turns.push(SEER_CHECK_TURN, SEER_END_TURN)
      end
      if all_roles.include?(WHITEWOLF) || all_roles.include?(WEREWOLF)
        room_included_turns.push(WOLF)
      end
      if all_roles.include?(WITCH) then room_included_turns.push(WITCH) end
      room_included_turns.push(DAY_TIME)

      current_turn_index = room_included_turns.index(hash['turn'])
      if current_turn_index.nil?
        raise MessagesHelper::SkillUseError.new("轮次异常 #{hash['turn']}不在游戏中")
      end
      turns_max_index = room_included_turns.size - 1
      if current_turn_index < turns_max_index
        current_turn_index += 1
      end
      next_turn = room_included_turns[current_turn_index]

      # if it's day time, update last night info display
      if next_turn == DAY_TIME
        update_last_night_info(hash)
      end
      hash['turn'] = next_turn
      hash['turn_display'] = GAME_TURN_DISPLAY_MAP[next_turn]
      hash.to_json
    end


    def update_last_night_info(hash)
      killed = []
      last_night = hash['night']
      last_night_kill = hash['night_actions'][last_night][WOLF_KILL]
      last_night_guard = hash['night_actions'][last_night][DEFENDER_GUARD]
      last_night_cure = hash['night_actions'][last_night][WITCH_SAVE]
      last_night_poison = hash['night_actions'][last_night][WITCH_KILL]

      if last_night_kill != 'not kill' && last_night_cure == 'false'
        killed.push(last_night_kill)
      end
      killed.delete(last_night_guard)

      if hash[GUARD_RULE] == GUARD_CURE_IS_DEAD
        if last_night_kill == last_night_guard && last_night_cure == 'true'
          killed.push(last_night_kill)
        end
      end
      unless last_night_poison == 'not kill'
        killed.push(last_night_poison)
      end
      killed.uniq!

      if killed.size == 0
        hash['last_night_info_display'] = "昨夜是平安夜"
      else
        hash['last_night_info_display'] = "昨夜死亡的有: #{killed.join('号,')}"
        # TODO: update seats => n => status
      end
      hash.to_json
    end

    # Update witch save info
    def update_witch_save_info(hash)
      tonight = hash['night']
      tonight_kill = hash['night_actions'][tonight][WOLF_KILL]

      if hash.include?('drug_used') && hash['drug_used'] == 'true'
        hash['witch_save_display'] = '解药已用 不显示刀型'
      elsif tonight_kill == 'not kill'
        hash['witch_save_display'] = '今夜无人死亡'
      else
        hash['witch_save_display'] = "今夜死亡的是: #{tonight_kill}号"
      end
      hash.to_json
    end
end
