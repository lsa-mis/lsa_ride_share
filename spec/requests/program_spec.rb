require 'rails_helper'
#  Written with chatGPT and Jason Swett
RSpec.describe "Programs", type: :request do
  describe 'login success' do
    it 'displays welcome message on programs page after successful login' do
      user = FactoryBot.create(:user)
 
      # Setup mock auth hash here or in a support file
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new({
        provider: 'saml',
        uid: '123456',
        info: {
          email: user.email,
          name: user.display_name,
          uniqname: user.uniqname,
          # ... other attributes ...
        }
      })

      # Simulate login by setting session variables
      post user_saml_omniauth_callback_path # Replace with your actual callback path

      # Now access the protected page
      get programs_path

      # Follow the redirect if one occurs
      follow_redirect!
      # puts response.body
      expect(response.body).to include("Welcome")
    end
  end
end

