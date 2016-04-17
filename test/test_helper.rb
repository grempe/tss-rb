# coveralls.io and coco are incompatible. Run each in their own env.
if ENV['TRAVIS'] || ENV['CI'] || ENV['JENKINS_URL'] || ENV['TDDIUM'] || ENV['COVERALLS_RUN_LOCALLY']
  # coveralls.io : web based code coverage
  require 'coveralls'
  Coveralls.wear!
else
  # coco : local code coverage
  require 'coco'
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'tss'

require 'minitest/autorun'
require 'minitest/pride'
