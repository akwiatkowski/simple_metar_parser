$:.unshift(File.dirname(__FILE__))

module SimpleMetarParser
  class Wind < Base

    def reset
      @winds = Array.new
      @winds_variable_directions = Array.new
    end

    KNOTS_TO_METERS_PER_SECOND = 1.85 / 3.6
    KILOMETERS_PER_HOUR_TO_METERS_PER_SECOND = 1.0 / 3.6

    def decode_split(s)
      decode_wind(s)
      decode_wind_variable(s)
    end

    def post_process
      recalculate_winds
    end

    # Wind parameters in meters per second
    def decode_wind(s)

      if s =~ /(\d{3})(\d{2})G?(\d{2})?(KT|MPS|KMH)/
        # different units
        wind = case $4
                 when "KT" then
                   $2.to_f * KNOTS_TO_METERS_PER_SECOND
                 when "MPS" then
                   $2.to_f
                 when "KMH" then
                   $2.to_f * KILOMETERS_PER_HOUR_TO_METERS_PER_SECOND
                 else
                   nil
               end

        wind_max = case $4
                     when "KT" then
                       $3.to_f * KNOTS_TO_METERS_PER_SECOND
                     when "MPS" then
                       $3.to_f
                     when "KMH" then
                       $3.to_f * KILOMETERS_PER_HOUR_TO_METERS_PER_SECOND
                     else
                       nil
                   end

        # wind_max is not less than normal wind
        if wind_max < wind or wind_max.nil?
          wind_max = wind
        end

        @winds << {
          :wind => wind,
          :wind_max => wind_max,
          :wind_direction => $1.to_i
        }
      end

      # variable/unknown direction
      if s =~ /VRB(\d{2})(KT|MPS|KMH)/
        wind = case $2
                 when "KT" then
                   $1.to_f * KNOTS_TO_METERS_PER_SECOND
                 when "MPS" then
                   $1.to_f
                 when "KMH" then
                   $1.to_f * KILOMETERS_PER_HOUR_TO_METERS_PER_SECOND
                 else
                   nil
               end

        @winds << {
          :wind => wind
        }

      end
    end

    # Variable wind direction
    def decode_wind_variable(s)
      if s =~ /(\d{3})V(\d{3})/
        @winds_variable_directions << {
          :wind_variable_direction_from => $1.to_i,
          :wind_variable_direction_to => $2.to_i,
          :wind_direction => ($1.to_i + $2.to_i) / 2,
          :wind_variable => true
        }
      end
    end

    # Calculate wind parameters, some metar string has multiple winds recorded
    def recalculate_winds
      wind_sum = @winds.collect { |w| w[:wind] }.inject(0) { |b, i| b + i }
      @wind = wind_sum.to_f / @winds.size
      if @winds.size == 1
        @wind_direction = @winds.first[:wind_direction]
      else
        @wind_direction = nil
      end
    end

    # Wind speed in meters per second
    attr_reader :wind
    alias_method :wind_speed, :wind

    # Direction of wind
    attr_reader :wind_direction

    # Wind speed in knots
    def wind_speed_knots
      return self.wind if self.wind.nil?
      return self.wind / KNOTS_TO_METERS_PER_SECOND
    end

    # Wind speed in KM/H
    def wind_speed_kmh
      return self.wind if self.wind.nil?
      return self.wind / KILOMETERS_PER_HOUR_TO_METERS_PER_SECOND
    end

    # Meters per second
    def mps
      self.wind
    end

    # Kilometers per hour
    def kmh
      self.wind_speed_kmh
    end

    # Knots
    def knots
      self.wind_speed_knots
    end

    # Wind direction
    def direction
      self.wind_direction
    end

  end
end