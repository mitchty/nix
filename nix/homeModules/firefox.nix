{
  pkgs,
  lib,
  ...
}:
{
  # Mostly yeeted from here https://gitlab.com/usmcamp0811/dotfiles/-/blob/fb584a888680ff909319efdcbf33d863d0c00eaa/modules/home/apps/firefox/default.nix
  #
  # TODO: get this working on macos, this only works on linux
  #
  # Also problematic is this firefox module is 23.11 only, need to debug the hokey segfault in emacs with 23.11 setups with treesitter.
  programs.firefox = {
    enable = true;
    package = pkgs.unstable.firefox;
    policies = {
      CaptivePortal = true;
      DisableFirefoxStudies = true;
      DisableFormHistory = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DNSOverHTTPS = {
        Enabled = false;
      };
      EncryptedMediaExtensions = {
        Enabled = false;
      };
      FirefoxHome = {
        Pocket = false;
        SponsoredPocket = false;
        SponsoredTopSites = false;
      };
      HardwareAcceleration = true;
      Homepage = {
        StartPage = "none";
      };
      NetworkPrediction = false;
      NewTabPage = false;
      NoDefaultBookmarks = false;
      OfferToSaveLogins = false;
      OfferToSaveLoginsDefault = false;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      PasswordManagerEnabled = false;
      Permissions = {
        Location = {
          BlockNewRequests = true;
        };
        Notifications = {
          BlockNewRequests = true;
        };
      };
      # PopupBlocking = { Default = false; };
      PromptForDownloadLocation = true;
      SanitizeOnShutdown = false;
      SearchSuggestEnabled = false;
      ShowHomeButton = true;
      UserMessaging = {
        WhatsNew = false;
        SkipOnboarding = true;
      };
    };
    profiles = {
      default =
        let
          hidetabstoolbar = (
            pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/MrOtherGuy/firefox-csshacks/master/chrome/hide_tabs_toolbar.css";
              sha256 = "sha256-PI1Lj+Qzos4B1kGpOd2fm2hZCYOPQhnOiS0YrGfGnPk=";
            }
          );
        in
        {
          id = 0;
          name = "default";
          isDefault = true;
          userChrome = ''
            @import url(${hidetabstoolbar});

            :root {
            	--navbar-height: 48px;
            	--wc-height: 16px;
            	--wc-left-margin: 10px;
            	--wc-red: hsl(-10, 90%, 60%);
            	--wc-yellow: hsl(50, 90%, 60%);
            	--wc-green: hsl(160, 90%, 40%);
            	--sidebar-collapsed-width: var(--navbar-height);
            	--sidebar-width: 250px;
            	--transition-duration: 0.2s;
            	--transition-ease: ease-out;
            }

            #nav-bar {
            	margin-right: calc(var(--wc-height) * 6 + var(--wc-left-margin));
            	padding: calc((var(--navbar-height) - 40px) / 2) 0;
            }
          '';
          extensions.packages =
            with pkgs.nur.repos.rycee.firefox-addons;
            [
              auto-tab-discard
              bitwarden
              cookies-txt
              greasemonkey
              i-dont-care-about-cookies
              sidebery
              ublacklist
              ublock-origin
              user-agent-string-switcher
              karakeep
            ]
            ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
              plasma-integration
            ];
          settings = {
            "apz.allow_double_tap_zooming" = false;
            "apz.allow_zooming" = true;
            "apz.gtk.touchpad_pinch.enabled" = true;
            "browser.aboutConfig.showWarning" = false;
            "browser.startup.page" = 3;
            "browser.tabs.loadInBackground" = true;
            "browser.tabs.warnOnClose" = false;
            "browser.urlbar.shortcuts.bookmarks" = false;
            "browser.urlbar.shortcuts.history" = false;
            "browser.urlbar.shortcuts.tabs" = false;
            "browser.urlbar.update2" = false;
            "dom.w3c.touch_events.enabled" = true;
            "dom.w3c_touch_events.legacy_apis.enabled" = true;
            "privacy.clearOnShutdown.history" = false;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          };
        };
    };
  };
}
