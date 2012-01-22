$:.unshift(File.dirname(__FILE__))

module SimpleMetarParser
  class Pressure < Base

    HG_INCH_TO_HPA = 1013.0/2992.1
    HG_MM_TO_HPA = HG_INCH_TO_HPA * 25.4

    def reset
      @pressure = nil
    end

    attr_reader :pressure

    def decode_split(s)
      # Europe
      if s =~ /Q(\d{4})/
        @pressure = $1.to_i
      end
      # US
      if s =~ /A(\d{4})/
        #1013 hPa = 29.921 inNg
        @pressure=(($1.to_f) * HG_INCH_TO_HPA).round
      end
    end

    def pressure_hg_mm
      (@pressure / HG_MM_TO_HPA).round
    end

    def pressure_hg_inch
      (@pressure / HG_INCH_TO_HPA).round
    end

  end
end