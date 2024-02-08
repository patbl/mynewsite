# frozen_string_literal: true

require "lib/donation"
require "lib/donation_data_fetcher"

# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
end

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

configure :production do
  activate :directory_indexes
end

Haml::TempleEngine.disable_option_validator!
