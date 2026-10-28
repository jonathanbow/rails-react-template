# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe "associations" do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value("a@example.com").for(:email) }
    it { is_expected.not_to allow_value("not-an-email").for(:email) }
    it { is_expected.to validate_length_of(:password).is_at_least(12) }
  end

  describe "normalization" do
    it "strips and downcases the email" do
      expect(build(:user, email: "  Foo@Example.COM ").email).to eq("foo@example.com")
    end
  end

  describe "changing the email" do
    it "marks the user unverified" do
      user = create(:user)
      user.update!(email: "changed@example.com")
      expect(user).not_to be_verified
    end
  end
end
