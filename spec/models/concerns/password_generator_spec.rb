# frozen_string_literal: true

require "rails_helper"

RSpec.describe PasswordGenerator do
  subject { User }

  describe "public instance methods" do
    context "responds to its methods" do
      it { expect(subject).to respond_to(:generate_random_pw) }
    end

    context "#generate_random_pw" do
      context "add parts to be a valid password" do
        before do
          allow(Devise)
            .to receive(:friendly_token)
            .with(described_class::MAX_LENGTH)
            .and_return("_" * described_class::MAX_LENGTH)
        end

        it "generates a pw with an upcase character" do
          expect(subject.generate_random_pw).to match(/[A-Z]/)
        end

        it "generates a pw with a lower case character" do
          expect(subject.generate_random_pw).to match(/[a-z]/)
        end

        it "generates a pw with an integer" do
          expect(subject.generate_random_pw).to match(/[0-9]/)
        end
      end

      context "length variations" do

        # This is basically a regression test against devise:
        it "is known to depend on unsafe token lengths form devise" do
          expect(Devise.friendly_token(17).length).not_to be(17)
          expect(Devise.friendly_token(17).length).to be(16)
        end

        it "generates a pw with a default length of 50" do
          expect(subject.generate_random_pw.length).to eq(50)
        end

        # Devise is not very safe in generating defined token lengths. This is needed to avoid
        # surprises. We're taking 10 samples.
        (11..20).to_a.each do |length|
          it "is able to generate a pw with the length of #{length}" do
            expect(subject.generate_random_pw(length).length).to eq(length)
          end
        end
      end
    end
  end

  it "exposes an instance method as well" do
    expect(User.new).to respond_to(:generate_random_pw_delegate)
  end

  it "delegates the instance method to the class method" do
    expect(User).to receive(:generate_random_pw)
    User.new.generate_random_pw_delegate
  end
end
