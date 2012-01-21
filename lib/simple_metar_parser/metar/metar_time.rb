$:.unshift(File.dirname(__FILE__))

module SimpleMetarParser
  class MetarTime < Base

    def year
      self.parent.year
    end

    def month
      self.parent.month
    end

    def reset
      @time = nil
    end

    def decode_split(s)
      if s =~ /(\d{2})(\d{2})(\d{2})Z/
        @time = Time.utc(self.year, self.month, $1.to_i, $2.to_i, $3.to_i, 0, 0)
      end
    end

    # Time "from"
    attr_reader :time
    alias :time_from :time

    # Interval of one metar
    def time_interval
      self.parent.options[:time_interval]
    end

    # End of time period
    def time_to
      self.time_from + self.time_interval
    end


  end
end