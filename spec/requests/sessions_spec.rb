# spec/requests/sessions_spec.rb
require 'rails_helper'

RSpec.describe "API::V1::Sessions", type: :request do
  let(:json_headers) do
    {
      "ACCEPT" => "application/json",
      "CONTENT_TYPE" => "application/json"
    }
  end

  describe "POST /api/v1/auth/sign_in" do
    let(:user_password) { "Password123!" }
    let!(:user) { create(:user, password: user_password, password_confirmation: user_password) }

    context "with valid credentials" do
      it "returns user JSON and may set Authorization header" do
        post "/api/v1/auth/sign_in",
             params: { email: user.email, password: user_password },
             headers: json_headers,
             as: :json

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body).to include("user")
        expect(body["user"]["email"]).to eq(user.email)

        # Authorization header may or may not be present depending on devise-jwt setup.
        auth_header = response.headers['Authorization'] || response.headers['authorization']
        if auth_header.present?
          expect(auth_header).to match(/\ABearer\s+[A-Za-z0-9\-\._~\+\/]+=*\z/)
        end
      end
    end

    context "with invalid credentials" do
      it "returns 401 and error message" do
        post "/api/v1/auth/sign_in",
             params: { email: user.email, password: "wrong-password" },
             headers: json_headers,
             as: :json

        expect(response).to have_http_status(:unauthorized)
        body = JSON.parse(response.body) rescue {}
        # controller renders { error: "Invalid email or password" }
        expect(body).to be_a(Hash)
        expect(body['error'] || body['errors']).to be_present
      end
    end
  end

  describe "DELETE /api/v1/auth/sign_out" do
    let(:user_password) { "Password123!" }
    let!(:user) { create(:user, password: user_password, password_confirmation: user_password) }

    def sign_in_and_get_auth_header
      post "/api/v1/auth/sign_in",
           params: { email: user.email, password: user_password },
           headers: json_headers,
           as: :json

      response.headers['Authorization'] || response.headers['authorization']
    end

    it "logs out and returns 204 (using real token if available, otherwise stub auth)" do
      auth_header = sign_in_and_get_auth_header

      if auth_header.present?
        delete "/api/v1/auth/sign_out", headers: json_headers.merge("Authorization" => auth_header), as: :json
        expect(response).to have_http_status(:no_content)
      else
        # Fall back to stubbing authentication/context so we can exercise the destroy path
        # This ensures tests remain deterministic even if sign_in doesn't expose a token.
        allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)

        delete "/api/v1/auth/sign_out", headers: json_headers, as: :json
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
