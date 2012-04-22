require 'rubygems'
require 'csv'
require 'fileutils'
require 'yaml'
require 'capybara'
require 'capybara/dsl'
require 'capybara/firebug'
require 'selenium/webdriver'
require "highline/import"
require 'ruby-debug'

config_file = File.join(File.dirname(__FILE__), 'creds.yml')
config = YAML::load(File.read(config_file)) || {} rescue {}
puts config.to_hash.inspect
config[:login_page] ||= "https://www.my.commbank.com.au/netbank/Logon/Logon.aspx"
config[:login] ||= ask('client no')

File.open(config_file, 'w') {|f| f.write config.to_yaml }

password = ask('password')  { |q| q.echo = "x" } # Don't store in config!

Capybara.default_driver = :selenium_with_firebug
include Capybara::DSL
visit config[:login_page]
fill_in('txtMyClientNumber_field', :with => config[:login])
fill_in('txtMyPassword_field', :with => password)
page.find(:css, '#btnLogon_field').click

click_on('View accounts')

accounts = page.find('select.MandatoryField').all('option')[1..-1].map {|e| e.text }

accounts.each do |account|
  output_path = 'accountdata/' + account + ".csv"
  select(account, :from => 'ctl00_BodyPlaceHolder_blockAccount_ddlAccount_field')
  click_on 'GO'
  begin
    while true do
      sleep(1)

      wait_until(6) { page.find(:css, '#showMore').visible? }
      click_on "Show more transactions..."
    end
  rescue Exception => e
    puts '*************'
    puts e.message
    puts e.inspect
    puts '*************'
  end

  data = []
  CSV.open(output_path, "wb") do |csv|
    page.all("#transactionsTableBody tr").each do |row|
      csv << row.all('td').map { |e| e.text }
    end
  end

  click_on('View accounts')
end

