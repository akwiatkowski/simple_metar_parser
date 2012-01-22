$:.unshift(File.dirname(__FILE__))

module SimpleMetarParser
  class Temperature < Base

    def reset
      @temperature = nil
      @dew = nil
    end

    attr_reader :temperature, :dew, :humidity

    def decode_split(s)
      # Temperature in Celsius degrees
      if s =~ /^(M?)(\d{2})\/(M?)(\d{2})$/
        if $1 == "M"
          @temperature = -1.0 * $2.to_f
        else
          @temperature = $2.to_f
        end

        if $3 == "M"
          @dew = -1.0 * $4.to_f
        else
          @dew = $4.to_f
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

    def post_process
      # Calculate relative humidity
      return if self.temperature.nil? or self.dew.nil?

      # http://github.com/brandonh/ruby-metar/blob/master/lib/metar.rb
      # http://www.faqs.org/faqs/meteorology/temp-dewpoint/

      es0 = 6.11 # hPa
      t0 = 273.15 # kelvin
      td = self.dew + t0 # kelvin
      t = self.temperature + t0 # kelvin
      lv = 2500000 # joules/kg
      rv = 461.5 # joules*kelvin/kg
      e = es0 * Math::exp(lv/rv * (1.0/t0 - 1.0/td))
      es = es0 * Math::exp(lv/rv * (1.0/t0 - 1.0/t))
      rh = 100 * e/es

      @humidity = rh.round
    end
  end

end
