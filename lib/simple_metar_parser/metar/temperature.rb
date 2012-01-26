$:.unshift(File.dirname(__FILE__))

module SimpleMetarParser
  class Temperature < Base

    def reset
      @temperature = nil
      @dew = nil
    end

    # Temperature in C
    attr_reader :temperature
    alias :degrees :temperature

    # Dew temperature
    attr_reader :dew

    # Relative humidity
    attr_reader :humidity

    # Wind chill index
    attr_reader :wind_chill

    # US Wind chill index
    attr_reader :wind_chill_us

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
      calculate_humidity
      calculate_wind_chill
    end

    def calculate_humidity
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

    def calculate_wind_chill
      return if self.temperature.nil? or self.parent.wind.wind_speed.nil?
      return if self.temperature > 10 or self.parent.wind.wind_speed_kmh < 4.8

      # http://en.wikipedia.org/wiki/Wind_chill
      v = self.parent.wind.wind_speed
      ta = self.temperature

      @wind_chill_us = 13.12 +
        0.6215 * ta -
        11.37 * v +
        0.3965 * ta * v

      @wind_chill = (10.0 * Math.sqrt(v) - v + 10.5)*(33.0 - ta)
    end

    
  end

end
