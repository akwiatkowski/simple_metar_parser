$:.unshift(File.dirname(__FILE__))

module SimpleMetarParser
  class MetarOther < Base

    def reset
      @station = nil
      @station_auto = false
    end

    attr_reader :station, :station_auto

    def decode_split(s)
      if s.strip == 'AO1'
        @station = :auto_without_precipitation
      elsif s.strip == 'A02'
        @station = :auto_with_precipitation
      end

      # fully automated station
      if s.strip == 'AUTO'
        @station_auto = true
      end

    end
  end
end