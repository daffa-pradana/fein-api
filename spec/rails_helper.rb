# This file is copied to spec/ when you run 'rails generate rspec:install'
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"

# Automatically require everything in spec/support/
Dir[Rails.root.join("spec", "support", "**", "*.rb")].each { |f| require f }

# Ensure test DB schema is up-to-date
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Fixture directory
  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]

  # Include FactoryBot syntax (so you can use build(:user) etc.)
  config.include FactoryBot::Syntax::Methods

  # Run each test in a transaction
  config.use_transactional_fixtures = true

  # Uncomment to automatically infer spec type from file location
  # config.infer_spec_type_from_file_location!

  # Filter Rails gems from backtraces
  config.filter_rails_from_backtrace!
  # config.filter_gems_from_backtrace("gem name")
end

# Configure Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
