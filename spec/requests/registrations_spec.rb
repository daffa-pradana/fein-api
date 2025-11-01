# spec/requests/registrations_spec.rb
require 'rails_helper'

RSpec.describe "API::V1::Registrations", type: :request do
  let(:json_headers) do
    {
      "ACCEPT" => "application/json",
      "CONTENT_TYPE" => "application/json"
    }
  end

  describe "POST /api/v1/auth/sign_up" do
    let(:valid_params) do
      {
        user: {
          email: "newuser@example.com",
          password: "Password123!",
          password_confirmation: "Password123!",
          first_name: "New",
          last_name: "User"
        }
      }
    end

    context "with valid params" do
      it "creates a user and returns user JSON with 201" do
        expect {
          post "/api/v1/auth/sign_up", params: valid_params, headers: json_headers, as: :json
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)

        body = JSON.parse(response.body)
        expect(body).to be_a(Hash)
        expect(body).to include("user")
        expect(body["user"]).to include("id", "email")
        expect(body["user"]["email"]).to eq("newuser@example.com")

        # Note: your controller does not set a JWT on signup, so we do not expect Authorization header here.
        auth_header = response.headers['Authorization'] || response.headers['authorization']
        expect(auth_header).to be_nil.or be_empty
      end
    end

    context "without password confirmation (confirmation not required by Devise)" do
      it "creates user (Devise allows missing password_confirmation) and returns 201" do
        bad = valid_params.deep_dup
        bad[:user].delete(:password_confirmation)

        expect {
          post "/api/v1/auth/sign_up", params: bad, headers: json_headers, as: :json
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)

        body = JSON.parse(response.body)
        expect(body).to have_key("user")
        created = User.find(body["user"]["id"])
        expect(created.valid_password?(bad[:user][:password])).to be true
      end
    end

    context "when email is already taken" do
      before do
        create(:user, email: valid_params[:user][:email])
      end

      it "does not create a new user and returns duplicate error (422)" do
        expect {
          post "/api/v1/auth/sign_up", params: valid_params, headers: json_headers, as: :json
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)

        body = JSON.parse(response.body)
        expect(body).to have_key("errors")
        # your controller returns user.errors.full_messages (array), so check for typical message
        expect(body["errors"].join(" ").downcase).to match(/email.*taken|has already been taken/)
      end
    end
  end
end
