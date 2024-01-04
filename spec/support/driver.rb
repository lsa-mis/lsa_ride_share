# browser_options = Selenium::WebDriver::Chrome::Options.new
# browser_options.add_argument('--window-size=1920,1080')

# webdriver_options = {
#   browser: :chrome,
#   options: browser_options
# }

# unless ENV['SHOW_BROWSER'].present?
#   browser_options.add_argument('--headless')
# end

# Capybara.register_driver :selenium_chrome do |app|
#   Capybara::Selenium::Driver.new(app, webdriver_options)
# end

# RSpec.configure do |config|
#   config.before(:each, type: :system) do
#     Capybara.default_driver = :selenium_chrome
#   end
# end
