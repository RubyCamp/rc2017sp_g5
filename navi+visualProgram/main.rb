require 'dxruby'

require_relative 'scene'
require_relative 'scene/load_scenes'

Window.caption = "NUMA TEAM"
Window.width   = 640
Window.height  = 480

require_relative "map"
require_relative "player_sprite"
require_relative "player"

Scene.set_current_scene(:title)
Window.loop do
  break if Input.key_push?(K_UP)
  Scene.play_scene
end

begin
  real_map = Map.new(File.join(File.dirname(__FILE__), "images", "map.dat"))

  map = Map.new(File.join(File.dirname(__FILE__), "images", "map.dat"))

  
  map.data.each do |ary|
    ary.each_with_index do |elm, idx|
      if elm == 3
        ary[idx] = 1
      elsif elm == 4
        ary[idx] = 3
      end
    end
  end


  player = PlayerSprite.new(0,0)
  current = map.start
  initialized = false

  # DXRubyでは、Window.loopの処理の最後に描画が行われるため、
  # フラグ管理して描画がスキップされないようにする。
  init = true          # 初回のフレームかどうか
  reach_goal = false   # ゴールに到達したか
  give_up = false      # ゴール到達不可能になったかどうか

  Window.loop do
    break if Input.key_down? K_E
    if reach_goal
      if real_map[current[0], current[1]]==Map::ITEM
        map=real_map
      else
        puts "goal!"
        player.run_final()
        #sleep 1
        break
      end
    end

    if give_up
      puts "give up!"
      sleep 2
      break
    end

    if init
      init = false
    else
      route = map.calc_route(current, map.goal)
      p route
      if route.length == 1
        if current == map.goal
          reach_goal = true
        else
          give_up = true
        end
      else
     #sleep 2
        if initialized == false
          2.times { player.turn_right }
          initialized = true
        end
        player.move_to(route[1])
 #ナビゲーターの情報
	print route[1][0]#x軸 
	print route[1][1] #y軸
	
        current = route[1]
      end
    end
    real_map.draw
    player.draw
  end
rescue Exception => e
  puts e.message
  puts e.backtrace

ensure

  
   Scene.set_current_scene(:ending)
   Window.loop do
   break if Input.key_push?(K_UP)
   Scene.play_scene
   end
   puts "終わり"

  player.close
end
