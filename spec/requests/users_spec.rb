require 'rails_helper'

RSpec.describe "API::V1::Users", type: :request do
  let(:json_headers) do
    {
      "ACCEPT" => "application/json",
      "CONTENT_TYPE" => "application/json"
    }
  end

  let(:password) { "Password123!" }
  let!(:user) { create(:user, password: password, password_confirmation: password) }

  # Helper: try to sign in via the public endpoint and return an auth header if present.
  # If not present, yield to a block that stub-auths the controller for tests that need current_user.
  def with_auth_header_for(u)
    post "/api/v1/auth/sign_in", params: { email: u.email, password: password }, headers: json_headers, as: :json
    auth_header = response.headers['Authorization'] || response.headers['authorization']

    if auth_header.present?
      yield({ "Authorization" => auth_header }.merge(json_headers))
    else
      # fallback: stub authenticate_user! and current_user on ApplicationController
      allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(u)
      yield(json_headers)
    end
  end

  describe "GET /api/v1/users/me" do
    it "returns the current user's profile" do
      with_auth_header_for(user) do |headers|
        get "/api/v1/users/me", headers: headers, as: :json

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body).to include("user")
        expect(body["user"]["email"]).to eq(user.email)
        expect(body["user"]["first_name"]).to eq(user.first_name)
        expect(body["user"]["last_name"]).to eq(user.last_name)
      end
    end
  end

  describe "PATCH /api/v1/users/me (profile update)" do
    context "with valid params" do
      it "updates first_name and last_name and returns user JSON" do
        with_auth_header_for(user) do |headers|
          patch "/api/v1/users/me",
                params: { user: { first_name: "NewFirst", last_name: "NewLast" } },
                headers: headers,
                as: :json

          expect(response).to have_http_status(:ok)
          body = JSON.parse(response.body)
          expect(body["user"]["first_name"]).to eq("NewFirst")
          expect(body["user"]["last_name"]).to eq("NewLast")
          user.reload
          expect(user.first_name).to eq("NewFirst")
          expect(user.last_name).to eq("NewLast")
        end
      end
    end

    context "with invalid params" do
      it "returns 422 and error messages when update fails" do
        # Force an invalid update (e.g., blank first_name if model validates presence)
        with_auth_header_for(user) do |headers|
          patch "/api/v1/users/me",
                params: { user: { first_name: "" } },
                headers: headers,
                as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          body = JSON.parse(response.body)
          expect(body).to have_key("errors")
        end
      end
    end
  end

  describe "PATCH /api/v1/users/me/email (change email)" do
    let(:new_email) { "changed@example.com" }

    context "without current_password" do
      it "returns 401 unauthorized and a helpful message" do
        with_auth_header_for(user) do |headers|
          patch "/api/v1/users/me/email",
                params: { email: new_email }, headers: headers, as: :json

          expect(response).to have_http_status(:unauthorized)
          body = JSON.parse(response.body) rescue {}
          expect(body["error"]).to match(/current_password.*required/i)
        end
      end
    end

    context "with incorrect current_password" do
      it "returns 401 and error message" do
        with_auth_header_for(user) do |headers|
          patch "/api/v1/users/me/email",
                params: { email: new_email, current_password: "wrong" },
                headers: headers, as: :json

          expect(response).to have_http_status(:unauthorized)
          body = JSON.parse(response.body) rescue {}
          expect(body["error"]).to match(/current password is incorrect/i)
        end
      end
    end

    context "with correct current_password" do
      it "updates the email and returns user JSON" do
        with_auth_header_for(user) do |headers|
          patch "/api/v1/users/me/email",
                params: { email: new_email, current_password: password },
                headers: headers, as: :json

          expect(response).to have_http_status(:ok)
          body = JSON.parse(response.body)
          expect(body["user"]["email"]).to eq(new_email)
          user.reload
          expect(user.email).to eq(new_email)
        end
      end
    end
  end

  describe "PATCH /api/v1/users/me/password (change password)" do
    context "with incorrect current_password or mismatched confirmation" do
      it "returns 422 when update fails" do
        with_auth_header_for(user) do |headers|
          patch "/api/v1/users/me/password",
                params: { current_password: "wrong", password: "New1!", password_confirmation: "New1!" },
                headers: headers, as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          body = JSON.parse(response.body) rescue {}
          expect(body).to have_key("errors")
        end
      end
    end

    context "with correct current_password and matching confirmation" do
      it "updates the password and returns user JSON" do
        new_pw = "NewPassword123!"
        with_auth_header_for(user) do |headers|
          patch "/api/v1/users/me/password",
                params: { current_password: password, password: new_pw, password_confirmation: new_pw },
                headers: headers, as: :json

          expect(response).to have_http_status(:ok)
          body = JSON.parse(response.body)
          expect(body["user"]["email"]).to eq(user.reload.email)

          # Ensure the user can authenticate with the new password
          expect(user.reload.valid_password?(new_pw)).to be true
        end
      end
    end
  end
end
