# name: accept-language
# about: Sets the language for non-logged-in users from their browser's accept-language header
# version: 0.2.1
# authors: scossar
# url: https://github.com/scossar/accept-language

enabled_site_setting :accept_language_enabled

register_asset 'stylesheets/accept-language.scss'

gem 'http_accept_language', '2.0.5'

after_initialize do

  User.class_eval do
    def preferred_locale?
      # Has the user selected a locale other than the site's default?
      self.locale.present?
    end

    def preferred_locale
      self.locale
    end
  end

  ApplicationController.class_eval do
    def set_locale
      if SiteSetting.allow_user_locale
        if !current_user
          I18n.locale = locale_from_http_header
        else
          if current_user.preferred_locale?
            I18n.locale = current_user.preferred_locale
          elsif SiteSetting.accept_language_overrides_default_locale
            I18n.locale = locale_from_http_header
          else
            I18n.locale = SiteSetting.default_locale
          end
        end
      else
        I18n.locale = SiteSetting.default_locale
      end
      # `I18n.ensure_all_loaded!` was added in Discourse version 1.5.
      if I18n.respond_to? :ensure_all_loaded!
        I18n.ensure_all_loaded!
      else
        I18n.fallbacks.ensure_loaded!
      end
    end

    def locale_from_http_header
      begin
        # Rails I18n uses underscores between the locale and the region; the request
        # headers use hyphens.
        available_locales = I18n.available_locales.map { |locale| locale.to_s.gsub(/_/, '-') }
        http_accept_language.language_region_compatible_from(available_locales).gsub(/-/, '_')
      rescue
        # If Accept-Language headers are not set.
        I18n.default_locale
      end
    end
  end

  ApplicationHelper.class_eval do
    def rtl?
      ['ar', 'fa_IR', 'he'].include? I18n.locale.to_s
    end

    def rtl_class
      'rtl' if rtl?
    end
  end

  # Add :locale to the user_params
  UsersController.class_eval do
    def user_params
      params.permit(:name, :email, :password, :username, :locale, :active)
          .merge(ip_address: request.remote_ip, registration_ip_address: request.remote_ip)
    end
  end
end
