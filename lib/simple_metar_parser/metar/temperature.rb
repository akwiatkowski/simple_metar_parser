$:.unshift(File.dirname(__FILE__))

module SimpleMetarParser
  class Temperature < Base

    def reset
      @temperature = nil
      @temperature_dew = nil
    end

    attr_reader :temperature, :temperature_dew

    def decode_split(s)
      # Temperature in Celsius degrees
      if s =~ /^(M?)(\d{2})\/(M?)(\d{2})$/
        if $1 == "M"
          @temperature = -1.0 * $2.to_f
        else
          @temperature = $2.to_f
        end

        if $3 == "M"
          @temperature_dew = -1.0 * $4.to_f
        else
          @temperature_dew = $4.to_f
        end

        return
      end

      # shorter version
      if s =~ /^(M?)(\d{2})\/$/
        if $1 == "M"
          @temperature = -1.0 * $2.to_f
        else
          @temperature = $2.to_f
        end

        return
      end
    end

  end
end