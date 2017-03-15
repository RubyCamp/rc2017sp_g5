require_relative 'ev3/ev3'

class Player
  LEFT_MOTOR = "B"
  RIGHT_MOTOR = "C"
  DISTANCE_SENSOR = "4"

  WHEEL_SPEED = 15

  attr_reader :distance

  def initialize(port)
    @brick = EV3::Brick.new(EV3::Connections::Bluetooth.new(port))
    @brick.connect
    @busy = false
    @grabbing = false
  end

  # 前進する
  def run_forward(speed=WHEEL_SPEED)
    operate do
      @brick.step_velocity(speed, 330, 40, *wheel_motors)
      @brick.motor_ready(*wheel_motors)
      @brick.reverse_polarity(*wheel_motors)
      @brick.step_velocity(speed, 328, 40, *wheel_motors)
      @brick.motor_ready(*wheel_motors)
    end
  end
  #最終処理
  def run_final(speed=WHEEL_SPEED)
    operate do
      @brick.step_velocity(speed, 1500, 40, *wheel_motors)
      @brick.motor_ready(*wheel_motors)
      @brick.reverse_polarity(*wheel_motors)
    end
  end

  # バックする
   def run_backward(speed=WHEEL_SPEED)
     operate do
       @brick.reverse_polarity(*wheel_motors)
       @brick.step_velocity(speed, 250, 40, *wheel_motors)
       @brick.motor_ready(*wheel_motors)
     end
   end

  # 右に回る
  def turn_right(speed=WHEEL_SPEED)
    operate do
      @brick.step_velocity(speed, 160, 40, *wheel_motors)
      @brick.motor_ready(*wheel_motors)
      @brick.reverse_polarity(*wheel_motors)
      @brick.step_velocity(speed, 159, 40, *wheel_motors)
      @brick.motor_ready(*wheel_motors)
     end
  end

  # 左に回る
  def turn_left(speed=WHEEL_SPEED)
     3.times do
	operate do
      @brick.step_velocity(speed, 160, 40, *wheel_motors)
      @brick.motor_ready(*wheel_motors)
	sleep 0.5
      @brick.reverse_polarity(*wheel_motors)
      @brick.step_velocity(speed, 159, 40, *wheel_motors)
      @brick.motor_ready(*wheel_motors)
      end
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
    @distance = @brick.get_sensor(DISTANCE_SENSOR, 0)
  end

  # センサー情報の更新とキー操作受け付け
  def run
    update
    run_forward if Input.keyDown?(K_UP)
    run_backward if Input.keyDown?(K_DOWN)
    turn_left if Input.keyDown?(K_LEFT)
    turn_right if Input.keyDown?(K_RIGHT)
    stop if [K_UP, K_DOWN, K_LEFT, K_RIGHT, K_W, K_S].all?{|key| !Input.keyDown?(key) }
  end

  # 終了処理
  def close
    stop
    reset
    @brick.disconnect
  end

  def reset
    @brick.clear_all
  end

  # "～_MOTOR" という名前の定数すべての値を要素とする配列を返す
  def all_motors
    @all_motors ||= self.class.constants.grep(/_MOTOR\z/).map{|c| self.class.const_get(c) }
  end

  def wheel_motors
    [LEFT_MOTOR, RIGHT_MOTOR]
  end
end
