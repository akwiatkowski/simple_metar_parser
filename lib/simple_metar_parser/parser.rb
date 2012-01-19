module SimpleMetarParser
  class Parser
    def self.parse(metar, options = {})
      return Metar.new(metar, options)
    end
  end
end