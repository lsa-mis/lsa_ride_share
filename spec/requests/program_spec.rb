require 'rails_helper'
#  Written with chatGPT and Jason Swett
RSpec.describe "Programs", type: :request do
  before do
    user = FactoryBot.create(:user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new({
      provider: 'saml',
      uid: '123456',
      info: {
        email: user.email,
        name: user.display_name,
        uniqname: user.uniqname
      }
    })
    post user_saml_omniauth_callback_path
  end 

  describe 'login success' do
    it 'displays welcome message on programs page' do
      get programs_path
      follow_redirect!
      # puts response.body
      expect(response.body).to include("Welcome")
    end
  end
end

