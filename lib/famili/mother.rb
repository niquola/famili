require 'date'
require 'famili/grand_mother'

unless Class.respond_to?(:class_attribute)
  require 'famili/class_attribute'
end

module Famili
  class Mother < Famili::GrandMother
    def save(model)
      model.save!
    end

    def unique
      "#{"%10.6f" % Time.now.to_f}#{object_id.abs}"
    end

    def sequence_number
      @sequence_number ||= self.class.objects_sequence_number
    end

    class << self
      def objects_sequence_number
        @sequence_number ||= 0
        @sequence_number += 1
      end
    end
  end
end
