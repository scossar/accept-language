## Accept Language

This Discourse plugin tries to set the locale for non-logged-in users from their
browser's Accept-Language request header. It also adds a locale selector to the
Discourse sign-up form. The default value of the locale selector is based off the
user's Accept-Language request header.

The logic is that if the site is visited by a non-logged-in user and the site allows
user-locales, the locale is set from the request headers. If there is a logged-in
user the locale is set from the user's effective locale. If there is no logged-in
user and user locales are disabled, the locale is set from the site default locale.

### Installation

Follow the [Install a Plugin](https://meta.discourse.org/t/install-a-plugin/19157) howto, using
`git clone https://github.com/scossar/accept-language` as the plugin command.

Once you've installed it, review the settings under plugins in the admin section of your
forum.

### Issues

The activation email that is sent to a new user is still being sent in the site's
default language. A temporary work-around for this is to translate the default locale's
activation email into your site's target languages - make it multilingual. I will add
an example of how to do that soon.

For sites where login is required to view any content, the 'login required welcome message'
is cached in the language of the first locale that accesses it.
