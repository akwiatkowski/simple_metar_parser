$:.unshift(File.dirname(__FILE__))

module SimpleMetarParser
  class Visibility < Base

    # max visibility
    MAX_VISIBILITY = 10_000

    # If visibility is greater than this it assume it is maximum
    NEARLY_MAX_VISIBILITY = 9_500

    def reset
      @visibility = nil
    end

    attr_reader :visibility

    def decode_split(s)
      # Visibility in meters

      # Europa
      if s =~ /^(\d{4})$/
        @visibility = $1.to_i
      end

      # US
      if s =~ /^(\d{1,3})\/?(\d{0,2})SM$/
        if $2 == ""
          @visibility = $1.to_i * 1600.0
        else
          @visibility = $1.to_f * 1600.0 / $2.to_f
        end
      end

      # constant max value
      if @visibility.to_i >= NEARLY_MAX_VISIBILITY
        @visibility = MAX_VISIBILITY
      end
    end
  end

end

