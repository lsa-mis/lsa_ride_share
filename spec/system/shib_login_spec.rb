require 'rails_helper'

def mock_login(info)
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new({
    provider: 'saml',
    uid: '123456',
    info: info
  })
  post user_saml_omniauth_callback_path
end

RSpec.describe "Programs", type: :request do

  describe 'login success' do
    it 'displays welcome message on programs page' do
      user = FactoryBot.create(:user)
      mock_login({
        email: user.email,
        name: user.display_name,
        uniqname: user.uniqname
      })
      follow_redirect!
      expect(response.body).to include("Welcome")
    end
  end

  describe 'login failure' do
    it 'displays welcome message on programs page' do
      user = FactoryBot.create(:user)
      mock_login({
        email: "kielbasa",
        name: user.display_name,
        uniqname: user.uniqname
      })
      expect(response.body).not_to include("Welcome")
    end
  end

end