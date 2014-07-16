#!/usr/bin/env ruby
require 'rubygems'
require 'csv'
require 'fileutils'
require 'yaml'
require 'capybara'
require 'capybara/dsl'
# require 'capybara/firebug'
require 'selenium/webdriver'
require 'highline/import'

config_file = File.join(File.dirname(__FILE__), 'creds.yml')
config = YAML::load(File.read(config_file)) || {} rescue {}
config[:login_page] ||= "https://www.my.commbank.com.au/netbank/Logon/Logon.aspx"
config[:login] ||= ask('client no')

File.open(config_file, 'w') {|f| f.write config.to_yaml }

password = ask('password')  { |q| q.echo = "x" } # Don't store in config!

Capybara.default_driver = :selenium
include Capybara::DSL
visit config[:login_page]
fill_in('txtMyClientNumber_field', :with => config[:login])
fill_in('txtMyPassword_field', :with => password)
page.find(:css, '#btnLogon_field').click

click_on('View accounts')

account_selector = 'select#ctl00_ContentHeaderPlaceHolder_ddlAccount_field'
accounts = page.find(account_selector).all('option')[1..-1].map {|e| e.text }

accounts.each do |account|
  output_path = 'accountdata/' + account + ".csv"
  page.find(account_selector).select(account)
  begin
    while true do
      page.find(:css, 'a.showMore').click
    end
  rescue Capybara::ElementNotFound => e
    # Expected; eventually there stops being more to show.
  rescue Exception => e
    puts '*************'
    puts e.message
    puts e.inspect
    puts '*************'
  end

  data = []
  CSV.open(output_path, "wb") do |csv|
    page.all("#transactionsTableBody tr").each do |row|
      csv << row.all('td').map(&:text)
    end
  end
  puts "Wrote account entries to #{output_path}"

end

