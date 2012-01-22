# ---------------------


# Temperature
def temperature
  @output[:temperature]
end

# Pressure in hPa
def pressure
  @output[:pressure]
end

# Snow amount in internal unit based on specials
def snow_metar
  @output[:snow_metar]
end

# Snow amount in read world units - mm (probably per m^2)
def snow
  @output[:snow]
end

# Snow amount in internal unit based on specials
def rain_metar
  @output[:rain_metar]
end

# Rain amount in read world units - mm (probably per m^2)
def rain
  @output[:rain]
end

# Visibility
def visibility
  @output[:visibility]
end

# City id
def city_id
  @city_id || @city_hash[:id]
end

# City name
attr_reader :city

# Country
attr_reader :city_country

# City Metar code
def city_metar
  @city_metar
end

# Processed data in Hash
attr_reader :output
# Processed data in Hash
alias_method :to_hash, :output

# Metar string was not downloaded
TYPE_ARCHIVED = :archived
# Metar string was just downloaded
TYPE_FRESH = :fresh
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


# Year
attr_reader :year

# Month
attr_reader :month

# Type from where come this metar, ex: :archived, :fresh
attr_reader :type

# max visibility
MAX_VISIBILITY = 10_000

# If visibility is greater than this it assume it is maximum
NEARLY_MAX_VISIBILITY = 9_500

# default metar time interval
TIME_INTERVAL = 30*60


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

# Enforce store
def store
  # send self to Storage
  Storage.instance.store(self) if valid?
end

# Convert decoded METAR to hash object prepared to store in DB. Not used by ActiveRecord storage engine.
def to_db_data
  return {
    :data => {
      :created_at => Time.now.to_i,
      :time_from => self.time_from,
      :time_to => self.time_to,
      :temperature => self.temperature,
      :pressure => self.pressure,
      :wind => self.wind,
      :snow_metar => self.snow_metar,
      :snow => self.snow,
      :rain_metar => self.rain_metar,
      :rain => self.rain,
      :provider => "'METAR'",
      # escaping slashes
      #:raw => "'#{@metar_string.gsub(/\'/,"\\\\"+'\'')}'",
      :raw => "'#{self.raw}'",
      :city_id => @city_id,
      :city => "'#{@city}'",
      :city_hash => @city_hash
    },
    :columns => [
      :created_at, :time_from, :time_to, :temperature, :pressure, :wind,
      :snow_metar, :rain_metar, :city_id, :raw
    ]
  }
end

private


# Temperature in Celsius degrees
def decode_temperature(s)
  if s =~ /^(M?)(\d{2})\/(M?)(\d{2})$/
    if $1 == "M"
      @output[:temperature] = -1.0 * $2.to_f
    else
      @output[:temperature] = $2.to_f
    end

    if $3 == "M"
      @output[:temperature_dew] = -1.0 * $4.to_f
    else
      @output[:temperature_dew] = $4.to_f
    end

    return
  end

  # shorter version
  if s =~ /^(M?)(\d{2})\/$/
    if $1 == "M"
      @output[:temperature] = -1.0 * $2.to_f
    else
      @output[:temperature] = $2.to_f
    end

    return
  end
end

# Pressure in hPa
def decode_pressure(s)
  # Europe
  if s =~ /Q(\d{4})/
    @output[:pressure] = $1.to_i
  end
  # US
  if s =~ /A(\d{4})/
    #1013 hPa = 29.921 inNg
    @output[:pressure]=(($1.to_f)*1013.0/2992.1).round
  end
end

# Visibility in meters
def decode_visibility(s)
  # Europa
  if s =~ /^(\d{4})$/
    @output[:visibility] = $1.to_i
  end

  # US
  if s =~ /^(\d{1,3})\/?(\d{0,2})SM$/
    if $2 == ""
      @output[:visibility] = $1.to_i * 1600.0
    else
      @output[:visibility] = $1.to_f * 1600.0 / $2.to_f
    end
  end

  # constant max value
  if @output[:visibility].to_i >= NEARLY_MAX_VISIBILITY
    @output[:visibility] = MAX_VISIBILITY
  end
end

# Cloudiness
def decode_clouds(s)

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

    @output[:clouds] << cloud
    @output[:clouds].uniq!
  end

  # obscured by clouds, vertical visibility
  if s =~ /^(VV)(\d{3}?)$/
    @output[:clouds] << {
      :coverage => CLOUD_OVERCAST,
      :vertical_visibility => $2.to_i * 30
    }

    @output[:clouds].uniq!
  end
end

# Calculate numeric description of clouds
def calculate_cloud
  @output[:cloudiness] = 0
  @output[:clouds].each do |c|
    @output[:cloudiness] = c[:coverage] if @output[:cloudiness] < c[:coverage]
  end
end

# CAVOK - clouds and visibility ok
def check_cavok(s)
  #CAVOK
  if s =~ /^(CAVOK)$/
    @output[:clouds] = [
      {
        :coverage => 0,
        :bottom => 0
      }
    ]
    @output[:visibility] = MAX_VISIBILITY
  end
end

# Calculate relative humidity
def calculate_humidity
  return if @output[:temperature_dew].nil? or @output[:temperature].nil?

  # http://github.com/brandonh/ruby-metar/blob/master/lib/metar.rb
  # http://www.faqs.org/faqs/meteorology/temp-dewpoint/

  es0 = 6.11 # hPa
  t0 = 273.15 # kelvin
  td = @output[:temperature_dew] + t0 # kelvin
  t = @output[:temperature] + t0 # kelvin
  lv = 2500000 # joules/kg
  rv = 461.5 # joules*kelvin/kg
  e = es0 * Math::exp(lv/rv * (1.0/t0 - 1.0/td))
  es = es0 * Math::exp(lv/rv * (1.0/t0 - 1.0/t))
  rh = 100 * e/es

  @output[:humidity] = rh
end

# Specials
def decode_specials(s)

  # description http://www.ofcm.gov/fmh-1/pdf/H-CH8.pdf

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

    @output[:specials] << {
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