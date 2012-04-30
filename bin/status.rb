#!/usr/bin/env ruby
require 'rubygems'
require 'csv'
require 'active_support'
balances = []
Dir.glob('accountdata/*.csv').map do |f|

  csv = CSV.read(f)
  if f =~ /Home Loan/
    balance_str = csv.map {|e| e[3] }.reject(&:blank?).first
  else
    balance_str = csv.map {|e| e.last }.reject(&:blank?).first
  end
  balance = balance_str.gsub(/\$|,/, '').to_f
  balance *= -1 if balance_str =~ /DR/
  puts "#{f.gsub('accountdata/', '')[0..8]}: #{balance_str} or #{balance}"
  balances << balance
end
puts balances.sum
