# name: accept-language
# about: Sets the language for non-logged-in users from their browser's accept-language header
# version: 0.1
# authors: scossar

gem 'http_accept_language', '2.0.5'

after_initialize do

  ApplicationController.class_eval do

    def set_locale
      # If there is no current user and user locales are enabled, use the 'accept_language'
      # request headers to find the best locale.
      # If there is a current user, use current_user.effective_locale to set the locale.
      # Finally, if there is no current user, set the locale to the default locale.
      I18n.locale = if !current_user && SiteSetting.allow_user_locale
                      available_locales = I18n.available_locales.map do |locale|
                        locale.to_s.gsub(/_/, '-')
                      end
                      http_accept_language.language_region_compatible_from(available_locales).gsub(/-/, '_')
                    else
                      current_user ? current_user.effective_locale : SiteSetting.default_locale
                    end
      I18n.fallbacks.ensure_loaded!
    end
  end

  ApplicationHelper.class_eval do
    def rtl?
      ['ar', 'fa_IR', 'he'].include?(current_locale)
    end

    def current_locale
      if SiteSetting.allow_user_locale
        if current_user
          current_user.locale
        else
          I18n.locale.to_s
        end
      else
        SiteSetting.default_locale
      end
    end

    def rtl_class
      'rtl' if rtl?
    end
  end
end
