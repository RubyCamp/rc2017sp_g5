require 'dxruby'
require_relative 'ev3/ev3'

class Player
  LEFT_MOTOR = "B"
  RIGHT_MOTOR = "C"
  DISTANCE_SENSOR = "4"
	COLOR_SENSOR = "3"
  PORT = "COM10"
  WHEEL_SPEED = 30
	RUN_FORWORD_TIME = 60*1

  attr_reader :distance,:input

  def initialize
    @brick = EV3::Brick.new(EV3::Connections::Bluetooth.new(PORT))
    @brick.connect
    @busy = false
    @grabbing = false
		@input=[100]
  end

  # 前進する
  def run_forward(speed=WHEEL_SPEED)
    operate do
      @brick.step_velocity(speed, 260, 40, *wheel_motors)
      @brick.motor_ready(*wheel_motors)
    end
  end

  # バックする
  def run_backward(speed=WHEEL_SPEED)
    operate do
      @brick.reverse_polarity(*wheel_motors)
      @brick.step_velocity(speed, 260, 40, *wheel_motors)
      @brick.motor_ready(*wheel_motors)
    end
  end

  # 右に回る
  def turn_right(speed=WHEEL_SPEED)
    operate do
      @brick.reverse_polarity(RIGHT_MOTOR)
      @brick.step_velocity(speed, 130, 60, *wheel_motors)
      @brick.motor_ready(*wheel_motors)
    end
  end

  # 左に回る
  def turn_left(speed=WHEEL_SPEED)
    operate do
      @brick.reverse_polarity(LEFT_MOTOR)
      @brick.step_velocity(speed, 130, 60, *wheel_motors)
      @brick.motor_ready(*wheel_motors)
    end
  end

  def get_count(motor)
    @brick.get_count(motor)
  end

  # 動きを止める
  def stop
    @brick.stop(true, *all_motors)
    @brick.run_forward(*all_motors)
  end

  # ある動作中は別の動作を受け付けないようにする
  def operate
    unless @busy
      @busy = true
      yield(@brick)
      stop
      @busy = false
    end
  end

  # センサー情報の更新
  def update
    @color = @brick.get_sensor(COLOR_SENSOR, 2)
  end

  def get_distance
    @distance = @brick.get_sensor(DISTANCE_SENSOR, 0)
  end

  # センサー情報の更新とキー操作受け付け
  def run
#    update
		reading
		running

    run_forward if Input.keyDown?(K_UP)
    run_backward if Input.keyDown?(K_DOWN)
    turn_left if Input.keyDown?(K_LEFT)
    turn_right if Input.keyDown?(K_RIGHT)
    stop if [K_UP, K_DOWN, K_LEFT, K_RIGHT, K_W, K_S].all?{|key| !Input.keyDown?(key) }

  end

	#読み取り処理
	def reading
		
		cm = get_distance #@distance

		i = 0

		while cm<=30
		  cm = get_distance
		  max=0
			if cm>=10
				while cm>=10 && cm<=30
				cm = get_distance
				puts cm

					if max<cm
						max=cm
					end	#if
				end	#while

				break if cm > 30

				if max<20
					@input[i]=0
				elsif max<30
					@input[i]=1
				end
				puts @input
				puts cm
				i +=1
			end	#if
    end	#while
		
	end
	#実行処理
	def running
		@input.each do |v|
			if @input[v]==0			#右方向転換
					turn_right
			elsif @input[v]==1	#前進
#					RUN_FORWORD_TIME.times do
						run_forward
#					end
			end
		end
	end

  # 終了処理
  def close
    stop
    @brick.clear_all
    @brick.disconnect
  end

  def reset
    @brick.clear_all
    #motors = wheel_motors  if motors.empty?
    #@brick.reset(*motors)
  end

  # "～_MOTOR" という名前の定数すべての値を要素とする配列を返す
  def all_motors
    @all_motors ||= self.class.constants.grep(/_MOTOR\z/).map{|c| self.class.const_get(c) }
  end

  def wheel_motors
    [LEFT_MOTOR, RIGHT_MOTOR]
  end
end

begin
  puts "starting..."
  font = Font.new(32)
  player = Player.new
  puts "connected"

	player.run

	player.input.each do |v|
		p player.input[v]
	end 

rescue Exception => e
  p e
  e.backtrace.each{|trace| puts trace}
# 終了処理は必ず実行する
ensure
  puts "closing..."
  player.close
  puts "finished"
end