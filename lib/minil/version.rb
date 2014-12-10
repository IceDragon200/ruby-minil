module Minil #:nodoc:
  module Version #:nodoc:
    MAJOR, MINOR, TEENY, PATCH = 0, 12, 0, nil
    STRING = [MAJOR, MINOR, TEENY, PATCH].compact.join('.')
  end
  VERSION = Version::STRING
end
