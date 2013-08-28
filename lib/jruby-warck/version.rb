module JrubyWarck
  module VERSION
    MAJOR = 0 
    MINOR = 1
    PATCH = 0

    STRING = [MAJOR, MINOR, PATCH].compact.join('.')

    def self.version
      STRING
    end
  end
end