module Minil #:nodoc:
  module Version #:nodoc:
    MAJOR = 0
    MINOR = 2
    PATCH = 0
    BUILD = nil
    STRING = [[MAJOR, MINOR, PATCH].compact.join("."), BUILD].compact.join("-").freeze
  end
  # backward compatibility
  VERSION = Version::STRING
end
