require 'rails_helper'

RSpec.describe 'Programs Index', type: :request do

  # def stub_env_for_omniauth(provider = "facebook", uid = "1234567", email = "bob@contoso.com", name = "John Doe")
  #   env = { "omniauth.auth" => { "provider" => provider, "uid" => uid, "info" => { "email" => email, "name" => name } } }
  #   # @controller.stub!(:env).and_return(env)
  #   env
  # end
  
  describe 'programs index' do
    it 'shows the right content' do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth["omniauth.auth"] = OmniAuth::AuthHash.new({
        :provider => 'saml',
        :uid => '123545'
        # etc.
      })
      user = create(:user)
      # session[:user_email] = user.email
      get programs_path, session: { user_email: user.email}
      # sleep(2)
      expect(response.body).to include("Programs")
    end
  end
end