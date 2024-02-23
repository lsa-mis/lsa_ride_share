module SpecHelper

  def mock_login(info)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new({
      provider: 'saml',
      uid: '123456',
      info: info
    })
    post user_saml_omniauth_callback_path
  end

end
