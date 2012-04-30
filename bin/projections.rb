#!/usr/bin/env ruby
require 'rubygems'
require 'active_support'
require 'lib/banking'

Dir.glob('accountdata/*.csv').map do |f|
  acct = TransactionReader.read f
  puts acct.status
  puts acct.recurring_transactions.inspect
end
