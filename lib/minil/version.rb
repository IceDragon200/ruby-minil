module Minil
  module Version
    MAJOR, MINOR, TEENY, PATCH = 0, 19, 0, nil
    STRING = [MAJOR, MINOR, TEENY, PATCH].compact.join('.')
  end
  VERSION = Version::STRING
end
