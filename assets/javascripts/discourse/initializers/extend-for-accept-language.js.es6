import CreateAccountController from 'discourse/controllers/create-account';
import UserModel from 'discourse/models/user';

export default {
  name: 'extend-for-create-account',

  initialize() {
    UserModel.reopenClass({
      // Adds the locale attribute
      createAccount(attrs) {
        return Discourse.ajax("/users", {
          data: {
            name: attrs.accountName,
            email: attrs.accountEmail,
            password: attrs.accountPassword,
            username: attrs.accountUsername,
            locale: attrs.accountLocale,
            password_confirmation: attrs.accountPasswordConfirm,
            challenge: attrs.accountChallenge,
            user_fields: attrs.userFields
          },
          type: 'POST'
        });
      }
    });

    CreateAccountController.reopen({
      accountLocale: I18n.locale,

      availableLocales: function() {
        return this.siteSettings.available_locales.split('|').map(s => ({ name: s, value: s }));
      }.property(),

      currentLocale: function() {
        return {name: I18n.locale, value: I18n.locale}
      }.property(),

      actions: {
        createAccount() {
          const self = this,
            // Adds accountLocale to the attributes
            attrs = this.getProperties('accountName', 'accountEmail', 'accountLocale', 'accountPassword', 'accountUsername', 'accountPasswordConfirm', 'accountChallenge'),
            userFields = this.get('userFields');

          // Add the userfields to the data
          if (!Ember.isEmpty(userFields)) {
            attrs.userFields = {};
            userFields.forEach(function(f) {
              attrs.userFields[f.get('field.id')] = f.get('value');
            });
          }

          this.set('formSubmitted', true);
          return Discourse.User.createAccount(attrs).then(function(result) {
            if (result.success) {
              // Trigger the browser's password manager using the hidden static login form:
              const $hidden_login_form = $('#hidden-login-form');
              $hidden_login_form.find('input[name=username]').val(attrs.accountUsername);
              $hidden_login_form.find('input[name=password]').val(attrs.accountPassword);
              $hidden_login_form.find('input[name=redirect]').val(Discourse.getURL('/users/account-created'));
              $hidden_login_form.submit();
            } else {
              self.flash(result.message || I18n.t('create_account.failed'), 'error');
              if (result.errors && result.errors.email && result.errors.email.length > 0 && result.values) {
                self.get('rejectedEmails').pushObject(result.values.email);
              }
              if (result.errors && result.errors.password && result.errors.password.length > 0) {
                self.get('rejectedPasswords').pushObject(attrs.accountPassword);
              }
              self.set('formSubmitted', false);
            }
            if (result.active && !Discourse.SiteSettings.must_approve_users) {
              return window.location.reload();
            }
          }, function() {
            self.set('formSubmitted', false);
            return self.flash(I18n.t('create_account.failed'), 'error');
          });
        }
      }
    });
  }
}