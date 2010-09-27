module Scorm
  module Datatypes
    
    class Timeinterval
      def initialize(seconds)
        @sec = seconds
      end
      
      def self.parse(str)
        case str
        when /(\d{2,4}):(\d{2}):(\d{2})/
          values = str.match(/(\d{2,4}):(\d{2}):(\d{2})/)
          hour = values[1].to_i
          minute = values[2].to_i
          second = values[3].to_i
        else
          date, time = str.split('T')
          if date
            year = date.match(/([0-9]+Y)/)[1].to_i if date.match(/([0-9]+Y)/)
            month = date.match(/([0-9]+M)/)[1].to_i if date.match(/([0-9]+M)/)
            day = date.match(/([0-9]+D)/)[1].to_i if date.match(/([0-9]+D)/)
          end
          if time
            hour = time.match(/([0-9]+H)/)[1].to_i if time.match(/([0-9]+H)/)
            minute = time.match(/([0-9]+M)/)[1].to_i if time.match(/([0-9]+M)/)
            second = time.match(/([0-9\.]+S)/)[1].to_f if time.match(/([0-9\.]+S)/)
          end
        end
        year = year || 0
        month = month || 0
        day = day || 0
        hour = hour || 0
        minute = minute || 0
        second = second || 0
        self.new((year*31557600) + (month*2629800) + (day*86400) + (hour*3600) + (minute*60) + second)
      end
      
      def to_i
        @sec.to_i
      end
      
      def to_f
        @sec.to_f
      end
      
      def to_s
        sec = self.to_i
        hours = (sec/60/60).to_i
        sec -= hours*60*60
        min = (sec/60).to_i
        sec -= min*60
        return "#{hours}:#{min}:#{sec}"
      end
    end
    
  end
end