module SpecHelper

  def mock_login(user)
  info = {
    email: user.email,
    name: user.display_name,
    uniqname: user.uniqname
  }
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new({
      provider: 'saml',
      uid: '123456',
      info: info
    })
    post user_saml_omniauth_callback_path
    
  end

  def stub_super_admin_access(user, unit_or_group = nil)
    allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(true)
    return unless unit_or_group.present?

    ldap_group = unit_or_group.respond_to?(:ldap_group) ? unit_or_group.ldap_group : unit_or_group
    allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, ldap_group).and_return(false)
  end

  def stub_admin_access(user, unit_or_group = nil)
    # allow(LdapLookup).to receive(:is_member_of_group?).with(anything, SUPER_ADMIN_LDAP_GROUP).and_return(false)

    if unit_or_group.present?
      ldap_group = unit_or_group.respond_to?(:ldap_group) ? unit_or_group.ldap_group : unit_or_group
      allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, anything).and_return(false)
      allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, ldap_group).and_return(true)
    else
      allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, anything).and_return(true)
    end
    # Ensure this user is not treated as super-admin (override the broader stub above).
    allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, SUPER_ADMIN_LDAP_GROUP).and_return(false)
  end

  def stub_non_admin_access(user)
    allow(LdapLookup).to receive(:is_member_of_group?).with(anything, SUPER_ADMIN_LDAP_GROUP).and_return(false)
    allow(LdapLookup).to receive(:is_member_of_group?).with(user.uniqname, anything).and_return(false)
  end
  
end
