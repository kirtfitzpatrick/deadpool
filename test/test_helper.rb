$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require 'simplecov'
SimpleCov.start

require 'deadpool'
# require "minitest/autorun"
require 'test/unit'
require 'mocha/test_unit'
