{
  self,
  config,
  pkgs,
  lib,
  user,
  targetDir,
  ...
}:
let
  shared-system-packages = import ../shared/system-packages.nix { inherit pkgs; };
in
{
  imports = [
    ../shared
    ./home-manager.nix
  ];
  environment = {
    etc."pam.d/sudo_local".text = ''
      auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so ignore_ssh
      auth       sufficient     pam_tid.so
    '';
    shells = [
      pkgs.zsh
    ];
    systemPackages = shared-system-packages ++ [
      pkgs.appcleaner
      pkgs.pam-reattach
    ];
  };
  homebrew = {
    enable = true;
    casks = [
      "ghostty"
    ];
    masApps = {
      "Goodnotes 6" = 1444383602;
      "KakaoTalk" = 869223134;
      "Messenger" = 1480068668;
      "SurfShark" = 1437809329;
      "Todoist" = 585829637;
      "WhatsApp" = 310633997;
    };
    onActivation.autoUpdate = true;
    onActivation.cleanup = "zap";
    onActivation.upgrade = true;
  };
  nix.enable = false;
  nix-homebrew = {
    inherit user;
    enable = true;
  };
  power.sleep = {
    computer = 20;
    display = 15;
  };
  programs = {
    _1password-gui.enable = false;
    fish.enable = true;
    zsh.enable = true;
  };
  services = {
    skhd.enable = true;
    yabai = {
      enable = true;
      enableScriptingAddition = true;
    };
  };
  system = {
    activationScripts.applications.text = lib.mkForce ''
      echo "setting up /Applications/Nix Apps..." >&2

      ourLink () {
        local link
        link=$(readlink "$1")
        [ -L "$1" ] && [ "''${link#*-}" = 'system-applications/Applications' ]
      }

      targetFolder='/Applications/Nix Apps'

      # Clean up old style symlink to nix store
      if [ -e "$targetFolder" ] && ourLink "$targetFolder"; then
        rm "$targetFolder"
      fi

      mkdir -p "$targetFolder"

      rsyncFlags=(
        --checksum
        --copy-unsafe-links
        --archive
        --delete
        --chmod=-w
        --no-group
        --no-owner
      )

      ${lib.getExe pkgs.rsync} "''${rsyncFlags[@]}" ${config.system.build.applications}/Applications/ "$targetFolder"
    '';
    checks.text = lib.mkAfter ''
      ensureAppManagement() {
        for appBundle in /Applications/Nix\ Apps/*.app; do
          if [[ -d "$appBundle" ]]; then
            if ! touch "$appBundle/.DS_Store" &> /dev/null; then
              return 1
            fi
          fi
        done

        return 0
      }

      if ! ensureAppManagement; then
        if [[ "$(launchctl managername)" != Aqua ]]; then
          # It is possible to grant the App Management permission to `sshd-keygen-wrapper`, however
          # there are many pitfalls like requiring the primary user to grant the permission and to
          # be logged in when `darwin-rebuild` is run over SSH and it will still fail sometimes...
          printf >&2 '\e[1;31merror: permission denied when trying to update apps over SSH, aborting activation\e[0m\n'
          printf >&2 'Apps could not be updated as `darwin-rebuild` requires Full Disk Access to work over SSH.\n'
          printf >&2 'You can either:\n'
          printf >&2 '\n'
          printf >&2 '  grant Full Disk Access to all programs run over SSH\n'
          printf >&2 '\n'
          printf >&2 'or\n'
          printf >&2 '\n'
          printf >&2 '  run `darwin-rebuild` in a graphical session.\n'
          printf >&2 '\n'
          printf >&2 'The option "Allow full disk access for remote users" can be found by\n'
          printf >&2 'navigating to System Settings > General > Sharing > Remote Login\n'
          printf >&2 'and then pressing on the i icon next to the switch.\n'
          exit 1
        else
          # The TCC service required to modify notarised app bundles is `kTCCServiceSystemPolicyAppBundles`
          # and we can reset it to ensure the user gets another prompt
          tccutil reset SystemPolicyAppBundles > /dev/null

          if ! ensureAppManagement; then
            printf >&2 '\e[1;31merror: permission denied when trying to update apps, aborting activation\e[0m\n'
            printf >&2 '`darwin-rebuild` requires permission to update your apps, please accept the notification\n'
            printf >&2 'and grant the permission for your terminal emulator in System Settings.\n'
            printf >&2 '\n'
            printf >&2 'If you did not get a notification, you can navigate to System Settings > Privacy & Security > App Management.\n'
            exit 1
          fi
        fi
      fi
    '';
    configurationRevision = self.rev or self.dirtyRev or null;
    defaults = {
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.0;
        persistent-apps = [
          "${pkgs.google-chrome}/Applications/Google Chrome.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
          "/Applications/Todoist.app"
          "${pkgs.spotify}/Applications/Spotify.app"
          "/Applications/Ghostty.app"
          "${pkgs.vscode}/Applications/Visual Studio Code.app"
          # "/Applications/VMware Fusion.app"
          "${pkgs.slack}/Applications/Slack.app"
          "/Applications/KakaoTalk.app"
          "/Applications/WhatsApp.app"
          "/Applications/Messenger.app"
          "/System/Applications/System Settings.app"
        ];
        launchanim = false;
        mru-spaces = false;
        show-recents = false;
        wvous-br-corner = 1;
      };
      finder = {
        _FXSortFoldersFirst = true;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = false;
        CreateDesktop = false;
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "clmv";
        FXRemoveOldTrashItems = true;
        NewWindowTarget = "Home";
      };
      hitoolbox.AppleFnUsageType = "Change Input Source";
      loginwindow.GuestEnabled = false;
      menuExtraClock = {
        Show24Hour = true;
        ShowAMPM = false;
        ShowDate = 1;
      };
      NSGlobalDomain = {
        AppleEnableMouseSwipeNavigateWithScrolls = false;
        AppleEnableSwipeNavigateWithScrolls = false;
        AppleICUForce24HourTime = true;
        AppleMeasurementUnits = "Centimeters";
        AppleScrollerPagingBehavior = true;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = false;
        AppleSpacesSwitchOnActivate = false;
        AppleTemperatureUnit = "Celsius";
      };
      WindowManager = {
        EnableStandardClickToShowDesktop = false;
        EnableTiledWindowMargins = false;
        EnableTilingByEdgeDrag = false;
        EnableTilingOptionAccelerator = false;
        EnableTopTilingByEdgeDrag = false;
        StandardHideDesktopIcons = true;
        StandardHideWidgets = true;
      };
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
    primaryUser = user;
    stateVersion = 6;
  };
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
  };
}
