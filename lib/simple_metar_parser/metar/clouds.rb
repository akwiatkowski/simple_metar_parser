$:.unshift(File.dirname(__FILE__))

module SimpleMetarParser
  class Clouds < Base

    # Cloud level - clear sky
    CLOUD_CLEAR = (0 * 100.0 / 8.0).round
    # Cloud level - few clouds
    CLOUD_FEW = (1.5 * 100.0 / 8.0).round
    #Cloud level - scattered
    CLOUD_SCATTERED = (3.5 * 100.0 / 8.0).round
    #Cloud level - broken
    CLOUD_BROKEN = (6 * 100.0 / 8.0).round
    #Cloud level - overcast
    CLOUD_OVERCAST = (8 * 100.0 / 8.0).round
    #Cloud level - not significant
    CLOUD_NOT_SIGN = (0.5 * 100.0 / 8.0).round

    def reset
      @clouds = Array.new
      @clouds_max = nil
    end

    attr_reader :clouds, :clouds_max

    def decode_split(s)
      if s =~ /^(SKC|FEW|SCT|BKN|OVC|NSC)(\d{3}?)$/
        cl = case $1
               when "SKC" then
                 CLOUD_CLEAR
               when "FEW" then
                 CLOUD_FEW
               when "SCT" then
                 CLOUD_SCATTERED
               when "BKN" then
                 CLOUD_BROKEN
               when "OVC" then
                 CLOUD_OVERCAST
               when "NSC" then
                 CLOUD_NOT_SIGN
               else
                 CLOUD_CLEAR
             end

        cloud = {
          :coverage => cl
        }
        # optionally cloud bottom
        unless '' == $2.to_s
          cloud[:bottom] = $2.to_i * 30
        end

        @clouds << cloud
        @clouds.uniq!
      end

      # obscured by clouds, vertical visibility
      if s =~ /^(VV)(\d{3}?)$/
        @clouds << {
          :coverage => CLOUD_OVERCAST,
          :vertical_visibility => $2.to_i * 30
        }

        @clouds.uniq!
      end

      if s =~ /^(CAVOK)$/
        # everything is awesome :)
      end

    end

    # Calculate numeric description of clouds
    def post_process
      @clouds_max = 0
      @clouds.each do |c|
        @clouds_max = c[:coverage] if @clouds_max < c[:coverage]
      end
    end
  end
end