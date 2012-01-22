$:.unshift(File.dirname(__FILE__))

module SimpleMetarParser
  class MetarSpecials < Base

    # description http://www.ofcm.gov/fmh-1/pdf/H-CH8.pdf

    def reset
      @specials = Array.new
    end

    attr_reader :specials

    attr_reader :snow_metar

    attr_reader :rain_metar

    def decode_split(s)
      decode_specials(s)
    end

    # Calculate numeric description of clouds
    def post_process
      calculate_rain_and_snow
    end

    def decode_specials(s)
      if s =~ /^(VC|\-|\+|\b)(MI|PR|BC|DR|BL|SH|TS|FZ|)(DZ|RA|SN|SG|IC|PE|GR|GS|UP|)(BR|FG|FU|VA|DU|SA|HZ|PY|)(PO|SQ|FC|SS|)$/
        intensity = case $1
                      when "VC" then
                        "in the vicinity"
                      when "+" then
                        "heavy"
                      when "-" then
                        "light"
                      else
                        "moderate"
                    end

        descriptor = case $2
                       when "MI" then
                         "shallow"
                       when "PR" then
                         "partial"
                       when "BC" then
                         "patches"
                       when "DR" then
                         "low drifting"
                       when "BL" then
                         "blowing"
                       when "SH" then
                         "shower"
                       when "TS" then
                         "thunderstorm"
                       when "FZ" then
                         "freezing"
                       else
                         nil
                     end

        precipitation = case $3
                          when "DZ" then
                            "drizzle"
                          when "RA" then
                            "rain"
                          when "SN" then
                            "snow"
                          when "SG" then
                            "snow grains"
                          when "IC" then
                            "ice crystals"
                          when "PE" then
                            "ice pellets"
                          when "GR" then
                            "hail"
                          when "GS" then
                            "small hail/snow pellets"
                          when "UP" then
                            "unknown"
                          else
                            nil
                        end

        obscuration = case $4
                        when "BR" then
                          "mist"
                        when "FG" then
                          "fog"
                        when "FU" then
                          "smoke"
                        when "VA" then
                          "volcanic ash"
                        when "DU" then
                          "dust"
                        when "SA" then
                          "sand"
                        when "HZ" then
                          "haze"
                        when "PY" then
                          "spray"
                        else
                          nil
                      end

        misc = case $5
                 when "PO" then
                   "dust whirls"
                 when "SQ" then
                   "squalls"
                 #when "FC " then "funnel cloud/tornado/waterspout"
                 when "FC" then
                   "funnel cloud/tornado/waterspout"
                 when "SS" then
                   "duststorm"
                 else
                   nil
               end

        # when no sensible data do nothing
        return if descriptor.nil? and precipitation.nil? and obscuration.nil? and misc.nil?

        @specials << {
          :intensity => intensity,
          :intensity_raw => $1,
          :descriptor => descriptor,
          :descriptor_raw => $2,
          :precipitation => precipitation,
          :precipitation_raw => $3,
          :obscuration => obscuration,
          :obscuration_raw => $4,
          :misc => misc,
          :misc_raw => $5
        }

      end
    end

    # Calculate precipitation in self defined units and aproximated real world units
    def calculate_rain_and_snow
      @snow_metar = 0
      @rain_metar = 0

      self.specials.each do |s|
        new_rain = 0
        new_snow = 0
        coefficient = 1
        case s[:precipitation]
          when 'drizzle' then
            new_rain = 5

          when 'rain' then
            new_rain = 10

          when 'snow' then
            new_snow = 10

          when 'snow grains' then
            new_snow = 5

          when 'ice crystals' then
            new_snow = 1
            new_rain = 1

          when 'ice pellets' then
            new_snow = 2
            new_rain = 2

          when 'hail' then
            new_snow = 3
            new_rain = 3

          when 'small hail/snow pellets' then
            new_snow = 1
            new_rain = 1
        end

        case s[:intensity]
          when 'in the vicinity' then
            coefficient = 1.5
          when 'heavy' then
            coefficient = 3
          when 'light' then
            coefficient = 0.5
          when 'moderate' then
            coefficient = 1
        end

        snow = new_snow * coefficient
        rain = new_rain * coefficient

        if @snow_metar < snow
          @snow_metar = snow
        end
        if @rain_metar < rain
          @rain_metar = rain
        end

      end

      # http://www.ofcm.gov/fmh-1/pdf/H-CH8.pdf page 3
      # 10 units means more than 0.3 (I assume 0.5) inch per hour, so:
      # 10 units => 0.5 * 25.4mm
      real_world_coefficient = 0.5 * 25.4 / 10.0

      @snow_metar *= real_world_coefficient
      @rain_metar *= real_world_coefficient
    end

  end
end