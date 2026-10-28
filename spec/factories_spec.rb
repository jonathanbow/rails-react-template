# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FactoryBot" do
  it "has valid factories" do
    FactoryBot.lint(traits: true)
  end
end
