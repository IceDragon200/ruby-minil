require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start


def spec_root_path(*args)
  File.join(File.dirname(__FILE__), *args)
end

def data_path(*args)
  spec_root_path('data', *args)
end

def output_path(*args)
  spec_root_path('output', *args)
end
