
# If metar string is valid, processed ok with basic data, and time was correct
def valid?
  if TYPE_ARCHIVED == @type
    if not @city_metar.nil? and
      not self.temperature.nil? and
      not self.wind.nil? and
      not self.time_from.nil? and
      self.time_from <= Time.now
      return true
    end

  elsif TYPE_FRESH == @type
    # time should be near now
    if not @city_metar.nil? and
      not self.temperature.nil? and
      not self.wind.nil? and
      not self.time_from.nil? and
      self.time_from <= Time.now and
      self.time_from >= (Time.now - 3*24*3600)
      return true
    end

  end

  return false
end




def decode_other(s)
  if s.strip == 'AO1'
    @output[:station] = :auto_without_precipitation
  elsif s.strip == 'A02'
    @output[:station] = :auto_with_precipitation
  end

  # fully automated station
  if s.strip == 'AUTO'
    @output[:station_auto] = true
  end

end

# Decode runway data. Not yet implemented.
def decode_runway(s)
  # BIAR 130700Z 17003KT 0350 R01/0900V1500U +SN VV001 M04/M04 Q0996
  # Runway 01, touchdown zone visual range is variable from a minimum of 0900 meters until a maximum of 1500 meters, and increasing
  # http://heras-gilsanz.com/manuel/METAR-Decoder.html
end
