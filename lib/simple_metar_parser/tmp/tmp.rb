
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






# Specials
def decode_specials(s)

  # description http://www.ofcm.gov/fmh-1/pdf/H-CH8.pdf


end

# Calculate precipitation in self defined units and aproximated real world units
def calculate_rain_and_snow
  @snow_metar = 0
  @rain_metar = 0

  @output[:specials].each do |s|
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

  @output[:snow_metar] = @snow_metar
  @output[:rain_metar] = @rain_metar

  # http://www.ofcm.gov/fmh-1/pdf/H-CH8.pdf page 3
  # 10 units means more than 0.3 (I assume 0.5) inch per hour, so:
  # 10 units => 0.5 * 25.4mm
  real_world_coefficient = 0.5 * 25.4 / 10.0

  @output[:snow] = @snow_metar * real_world_coefficient
  @output[:rain] = @rain_metar * real_world_coefficient

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
