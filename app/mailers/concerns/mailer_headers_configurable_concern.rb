module MailerHeadersConfigurableConcern
  extend ActiveSupport::Concern

  included do
    def configure_defaults_for_user(user)
      return if user.nil? || !user.is_a?(User) # not for super-admins

      I18n.locale = user.locale

      if user.preferred_domain_demarches_gouv_fr?
        Current.application_name = "demarches.gouv.fr"
        Current.host = ENV.fetch("APP_HOST")
        Current.contact_email = "contact@demarches.gouv.fr"
        Current.no_reply_email = NO_REPLY_EMAIL.sub("demarches-simplifiees.fr", "demarches.gouv.fr") # rubocop:disable DS/ApplicationName
      else
        Current.application_name = APPLICATION_NAME
        Current.host = ENV["APP_HOST_LEGACY"] || ENV.fetch("APP_HOST") # _LEGACY is optional, fallbagck to default when unset
        Current.contact_email = CONTACT_EMAIL
        Current.no_reply_email = NO_REPLY_EMAIL
      end

      @@original_default_from ||= self.class.default[:from]
      from = if @@original_default_from.include?(NO_REPLY_EMAIL)
        Current.no_reply_email
      else
        "#{Current.application_name} <#{Current.contact_email}>"
      end

      self.class.default from: from, reply_to: from
      self.class.default_url_options = { host: Current.host }
      self.class.asset_host = Current.application_base_url
    end

    def configure_defaults_for_email(email)
      user = User.find_by(email: email)

      configure_defaults_for_user(user)
    end
  end
end
