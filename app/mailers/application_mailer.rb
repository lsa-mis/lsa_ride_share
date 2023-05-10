class ApplicationMailer < ActionMailer::Base
  prepend_view_path "app/views/mailers"
  default from: "lsa-rideshare-admins@umich.edu"
  layout "mailer"
end
