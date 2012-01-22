$:.unshift(File.dirname(__FILE__))

module SimpleMetarParser
  class MetarSpecials < Base

    def reset
      @specials = Array.new
    end

    attr_reader :specials

    def decode_split(s)
      decode_specials(s)
    end

    # Calculate numeric description of clouds
    def post_process
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
  end
end