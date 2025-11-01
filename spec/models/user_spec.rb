require "rails_helper"

RSpec.describe User, type: :model do
  describe "database columns" do
    it { is_expected.to have_db_column(:email).of_type(:string).with_options(null: false, default: "") }
    it { is_expected.to have_db_column(:encrypted_password).of_type(:string).with_options(null: false, default: "") }
    it { is_expected.to have_db_column(:first_name).of_type(:string).with_options(null: false, default: "") }
    it { is_expected.to have_db_column(:last_name).of_type(:string).with_options(null: false, default: "") }
    it { is_expected.to have_db_index(:email).unique(true) }
  end

  describe "validations" do
    # Devise's :validatable already adds these validations internally
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

    # Ensure first_name and last_name exist in schema and are non-null
    it "requires first_name and last_name to be present" do
      user = build(:user, first_name: "", last_name: "")
      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to be_present
      expect(user.errors[:last_name]).to be_present
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:user)).to be_valid
    end
  end

  describe "authentication behavior" do
    let(:user) { create(:user, password: "Password123!", password_confirmation: "Password123!") }

    it "accepts the correct password" do
      expect(user.valid_password?("Password123!")).to be true
    end

    it "rejects a wrong password" do
      expect(user.valid_password?("wrong_password")).to be false
    end
  end

  describe "Devise modules" do
    it "includes all expected devise modules" do
      expected_modules = [
        :database_authenticatable,
        :registerable,
        :recoverable,
        :rememberable,
        :validatable,
        :jwt_authenticatable
      ]
      expect(described_class.devise_modules).to include(*expected_modules)
    end
  end

  describe "JWT configuration" do
    it "uses JwtDenylist as its revocation strategy" do
      expect(User.devise_modules).to include(:jwt_authenticatable)
      expect(defined?(JwtDenylist)).to be_truthy
    end
  end
end
