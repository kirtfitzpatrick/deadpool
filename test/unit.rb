
TEST_PATH = File.dirname(__FILE__)
Dir[TEST_PATH + '/unit/*.rb'].each { |test| require test }
Dir[TEST_PATH + '/unit/failover_protocols/*.rb'].each { |test| require test }
Dir[TEST_PATH + '/unit/monitors/*.rb'].each { |test| require test }

