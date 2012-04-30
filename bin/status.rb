#!/usr/bin/env ruby
require 'rubygems'
require 'active_support'
require 'lib/banking'

balances = []
Dir.glob('accountdata/*.csv').map do |f|
  acct = TransactionReader.read f
  puts acct.status
  balances << acct.balance
end
puts balances.sum
