$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'test/unit'

begin
  require 'mocha'
rescue LoadError
  abort "Install mocha with `gem install mocha`"
end

require 'deadpool'
