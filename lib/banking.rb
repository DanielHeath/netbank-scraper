#!/usr/bin/env ruby
require 'rubygems'
require 'active_support'
require 'csv'

class TransactionReader
  def self.read(filename)
    csv = CSV.read(filename)
    transactions = csv.map do |row|
      if filename =~ /Home Loan/
        balance_afterwards = parse_money row[4]
      else
        balance_afterwards = parse_money row[5]
      end
      if filename =~ /MasterCard/
        amount = parse_money(row[4]).to_f - parse_money(row[3]).to_f
      else
        amount = parse_money(row[3])
      end
      Transaction.new(:date => Date.parse(row[0]), :description => row[2], :amount => amount, :balance_afterwards => balance_afterwards)
    end
    account = Account.new filename.gsub('accountdata/', ''), transactions
  end

  def self.parse_money(str)
    return nil if str.blank?
    amount = str.gsub(/\$|,/, '').to_f
    amount *= -1 if str =~ /DR/
    amount
  end

end

class Transaction
  attr_reader :date, :description, :balance_afterwards, :amount

  def initialize(options)
    @amount = options[:amount]
    @date = options[:date]
    @description = options[:description]
    @balance_afterwards = options[:balance_afterwards]
  end

  def no_change?
    !amount
  end

  def credit?
    amount > 0
  end
  
  def debit?
    amount < 0
  end

end

class Account
  attr_reader :name, :number, :transactions

  def initialize(name, transactions=[])
    @number = name.gsub(/[^0-9]/, '')
    @name = name.gsub(/\.csv$/, '').gsub(/[0-9]/, '').strip
    @transactions = transactions.sort_by(&:date).reverse
  end

  def status
    "#{name}: #{balance_description}"
  end

  def balance
    # Not all account types have a 'balance afterwards field'; use the sum of balances instead.
    balance_from_balance_afterwards_field || balance_from_summing_transactions
  end

  def recurring_transactions
    all = {}
    recurring = []
    # TODO: Strip out non-alpha characters from transaction description for wider matching
    transactions.each {|t| all[t.description] ||= []; all[t.description].push t}
    all.each {|k, v| recurring.push(v) if v.length > 4}
    # TODO: Create a recurring transaction class (probably time to split classes into their own files, too)
    recurring
  end

  private

  def balance_from_balance_afterwards_field
    trim_balance @transactions.map(&:balance_afterwards).reject(&:blank?).first
  end

  def balance_from_summing_transactions
    trim_balance @transactions.map(&:amount).reject(&:blank?).sum
  end
  
  def trim_balance(balance)
    return nil unless balance
    (balance * 100).to_i / 100.0
  end

  def balance_description
    balance = balance_from_balance_afterwards_field
    balance ||= "#{balance_from_summing_transactions} (estimated; can't be sure without knowing the start balance)"
  end

end

