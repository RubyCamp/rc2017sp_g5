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

  # �O�i����
  def run_forward(speed=WHEEL_SPEED)
    operate do
      @brick.step_velocity(speed, 260, 40, *wheel_motors)
      @brick.motor_ready(*wheel_motors)
    end
  end

  # �o�b�N����
  def run_backward(speed=WHEEL_SPEED)
    operate do
      @brick.reverse_polarity(*wheel_motors)
      @brick.step_velocity(speed, 260, 40, *wheel_motors)
      @brick.motor_ready(*wheel_motors)
    end
  end

  # �E�ɉ��
  def turn_right(speed=WHEEL_SPEED)
    operate do
      @brick.reverse_polarity(RIGHT_MOTOR)
      @brick.step_velocity(speed, 130, 60, *wheel_motors)
      @brick.motor_ready(*wheel_motors)
    end
  end

  # ���ɉ��
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

  # �������~�߂�
  def stop
    @brick.stop(true, *all_motors)
    @brick.run_forward(*all_motors)
  end

  # ���铮�쒆�͕ʂ̓�����󂯕t���Ȃ��悤�ɂ���
  def operate
    unless @busy
      @busy = true
      yield(@brick)
      stop
      @busy = false
    end
  end

  # �Z���T�[���̍X�V
  def update
    @color = @brick.get_sensor(COLOR_SENSOR, 2)
  end

  def get_distance
    @distance = @brick.get_sensor(DISTANCE_SENSOR, 0)
  end

  # �Z���T�[���̍X�V�ƃL�[����󂯕t��
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

	#�ǂݎ�菈��
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
	#���s����
	def running
		@input.each do |v|
			if @input[v]==0			#�E�����]��
					turn_right
			elsif @input[v]==1	#�O�i
#					RUN_FORWORD_TIME.times do
						run_forward
#					end
			end
		end
	end

  # �I������
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

  # "�`_MOTOR" �Ƃ������O�̒萔���ׂĂ̒l��v�f�Ƃ���z���Ԃ�
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
# �I�������͕K�����s����
ensure
  puts "closing..."
  player.close
  puts "finished"
end