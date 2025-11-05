Rails.application.config.to_prepare do
  Devise.setup do |config|
    jwt_secret = ENV["DEVISE_JWT_SECRET_KEY"] || Rails.application.credentials.devise_jwt_secret_key
    raise "Set DEVISE_JWT_SECRET_KEY (env) or credentials.devise_jwt_secret_key" unless jwt_secret.present?

    config.jwt do |jwt|
      jwt.secret = jwt_secret

      jwt.dispatch_requests = [
        [ "POST", %r{^/api/v1/auth/sign_in$} ]
      ]

      jwt.revocation_requests = [
        [ "DELETE", %r{^/api/v1/auth/sign_out$} ]
      ]
    end
  end
end
