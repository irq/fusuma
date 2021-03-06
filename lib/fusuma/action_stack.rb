module Fusuma
  # manage actions
  class ActionStack < Array
    ELAPSED_TIME = 0.01

    def initialize(*args)
      super(*args)
    end

    def generate_event_trigger
      return unless enough_actions?
      action_type = detect_action_type
      vector = generate_vector(action_type)
      finger = detect_finger
      trigger = EventTrigger.new(finger, vector.direction, action_type)
      return unless vector.enough?(trigger)
      clear
      trigger
    end

    def push(gesture_action)
      super(gesture_action)
      clear if action_end?
    end
    alias << push

    private

    def generate_vector(action_type)
      case action_type
      when 'swipe'
        avg_swipe
      when 'pinch'
        avg_pinch
      end
    end

    def detect_finger
      last.finger
    end

    def avg_swipe
      move_x = avg_attrs(:move_x)
      move_y = avg_attrs(:move_y)
      Swipe.new(move_x, move_y)
    end

    def avg_pinch
      diameter = avg_attrs(:zoom)
      delta_diameter = diameter - first.zoom
      Pinch.new(delta_diameter)
    end

    def sum_attrs(attr)
      send('map') do |gesture_action|
        gesture_action.send(attr.to_sym.to_s)
      end.compact.inject(:+)
    end

    def avg_attrs(attr)
      sum_attrs(attr) / length
    end

    def action_end?
      last_action_name =~ /_END$/
    end

    def last_action_name
      return false if last.class != GestureAction
      last.action
    end

    def enough_actions?
      length > 2
    end

    def enough_elapsed_time?
      return false if length.zero?
      (last.time - first.time) > ELAPSED_TIME
    end

    def detect_action_type
      first.action =~ /GESTURE_(.*?)_/
      Regexp.last_match(1).downcase
    end
  end
end
