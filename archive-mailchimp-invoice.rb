#!/usr/bin/env ruby
#
# Archive Mailchimp invoice as PDF.
# Copyright 2023 Filip Zrust
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'selenium-webdriver', '~> 4.1'
  gem 'rotp', '~> 6.2'
end

date = ARGV.fetch(0) do
  now = Time.now
  ENV.fetch('MAILCHIMP_INVOICE_DATE', "#{now.year}-#{now.month}")
end
# In case the given date has more elements, we limit split to 3 instead of 2.
# By this, we make sure year (the first element) and month (the second
# element) are cleanly separated while the rest (everything as the third
# element) is ignored.
year, month, _ = date.split('-', 3)
DATE = Time.new year, month

secret_file = ->(name) { File.read(ENV.fetch("#{name}_FILE")) }
TWO_FACTOR_AUTH_SECRET = ENV.fetch('MAILCHIMP_2FA_SECRET', &secret_file)
PASSWORD = ENV.fetch('MAILCHIMP_PASSWORD', &secret_file)
USERNAME = ENV.fetch('MAILCHIMP_USERNAME', &secret_file)

BROWSER = ENV.fetch('WEBDRIVER_BROWSER').to_sym
HEADLESS = ENV['WEBDRIVER_HEADLESS']
REMOTE_URL = ENV['WEBDRIVER_REMOTE_URL']

wait = Selenium::WebDriver::Wait.new timeout: 60

options = Selenium::WebDriver::Options.send(BROWSER)
options.headless! if HEADLESS

if REMOTE_URL
  driver = Selenium::WebDriver::Driver.for :remote,
    capabilities: [options],
    url: REMOTE_URL
else
  driver = Selenium::WebDriver::Driver.for BROWSER,
    capabilities: [options]
end

at_exit { driver.quit }

driver.navigate.to 'https://login.mailchimp.com' \
  '/?referrer=%2Faccount%2Fbilling-history%2F'

#
# Close cookie consent
#

# Also useful as a check all the important scripts are load and initialized.
container = wait.until { driver.find_element id: 'onetrust-banner-sdk' }
wait.until { container.displayed? }
button = container.find_element class: 'onetrust-close-btn-handler'
wait.until { button.displayed? }
button.click

#
# Authenticate with username and password
#

field = wait.until { driver.find_element name: 'username' }
field.send_keys USERNAME

field = driver.find_element name: 'password'
field.send_keys PASSWORD

field.submit

#
# Authenticate with one-time password
#

field = wait.until do
  f = driver.find_element name: 'tfa_remember'
  f.displayed? && f
end
field.click if field.selected?

field = driver.find_element name: 'totp-token'
field.send_keys ROTP::TOTP.new(TWO_FACTOR_AUTH_SECRET).now

field.submit

at_exit do
  driver.navigate.to 'https://us17.admin.mailchimp.com/login/out'
  wait.until { driver.find_element name: 'username' }
end

#
# Search for invoice for particular month
#

frame = wait.until do
  f = driver.find_element id: 'fallback'
  f.displayed? && f
end
driver.switch_to.frame frame

MONTHS = %w|Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec|
DATE_RE = %r|\b#{MONTHS[DATE.month - 1]}\s+#{DATE.year}\b|

list = wait.until { driver.find_element id: 'billing-history' }
wait.until { list.find_element tag_name: 'li' }
items = list.find_elements tag_name: 'li'
found = items.find {|item| DATE_RE.match? item.text }
unless found
  puts "No invoice found for month #{DATE.month} in year #{DATE.year}."
  exit 1
end

link = found.find_element tag_name: 'a'
order_no = link.text.strip
link.click

driver.switch_to.default_content

#
# Open and modify the invoice for print
#

frame = wait.until do
  f = driver.find_element id: 'fallback'
  f.displayed? && f
end
driver.navigate.to frame['src']

back_link = wait.until { driver.find_element id: 'fallback-back-container' }
driver.execute_script <<~JS
  document.querySelector('##{back_link.dom_attribute('id')}').remove()
JS

#
# Print to PDF file
#

wait.until { driver.find_element link_text: 'Print' }

A4 = { width: 21.0, height: 29.7 }
result = driver.print_page page: A4

name = "#{order_no} #{DATE.strftime('%Y-%m')}.pdf"
print "Saving invoice to #{name}.."
File.write name, result.unpack('m')[0]
puts '.'
