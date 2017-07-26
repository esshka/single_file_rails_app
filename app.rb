begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"

  gem "rails"
  gem "sqlite3"
  gem "factory_girl_rails"
end

require "active_record"
require "action_controller/railtie"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: "memory")
# ActiveRecord::Schema.verbose = false
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :books, force: true do |t|
    t.string :name
    t.timestamps
  end

  create_table :categories, force: true do |t|
    t.string :name
    t.timestamps
  end

  create_table :categorizations, force: true do |t|
    t.references :book
    t.references :category
    t.boolean :primary, default: false, null: false
    t.timestamps
  end
end

class Book < ActiveRecord::Base
  has_many :categorizations
  has_many :categories, through: :categorizations
end

class Category < ActiveRecord::Base
  has_many :categorizations
  has_many :books, through: :categorizations

  def self.primaries
    Category.joins(:categorizations).merge(Categorization.primaries)
  end
end

class Categorization < ActiveRecord::Base
  belongs_to :book
  belongs_to :category

  def self.primaries
    where(primary: true)
  end
end

class TestApp < Rails::Application
  secrets.secret_token    = "secret_token"
  secrets.secret_key_base = "secret_key_base"

  config.logger = Logger.new($stdout)
  Rails.logger = config.logger

  routes.draw do
    resources :primary_categories, only: :index
  end
end

class PrimaryCategoriesController < ActionController::Base
  include Rails.application.routes.url_helpers

  def index
    @primary_categories = Category.primaries
    render inline: "# of primary categories: <%= @primary_categories.count %>"
  end
end


Rack::Handler::WEBrick.run(TestApp, :Port => 3000)
