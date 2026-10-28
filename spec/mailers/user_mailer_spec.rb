# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  let(:user) { create(:user) }

  describe "email_verification" do
    let(:mail) { described_class.with(user: user).email_verification }

    it "sends to the user's email" do
      expect(mail.to).to eq([ user.email ])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Verify your email")
    end
  end

  describe "password_reset" do
    let(:mail) { described_class.with(user: user).password_reset }

    it "sends to the user's email" do
      expect(mail.to).to eq([ user.email ])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Reset your password")
    end
  end
end
