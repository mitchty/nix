{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mitchty.iscsi;
in
{
  options.mitchty.iscsi = {
    enable = mkEnableOption "iSCSI initiator support";

    portal = mkOption {
      type = types.str;
      description = "iSCSI portal address (IP:port or hostname:port)";
      default = "s1.home.arpa:3260";
    };

    initiatorName = mkOption {
      type = types.str;
      description = "iSCSI initiator name (IQN)";
      default = "iqn.2000-01.${config.networking.hostName}:initiator";
    };

    auth = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            username = mkOption {
              type = types.str;
              description = "CHAP username for iSCSI authentication";
            };
            passwordSecretPath = mkOption {
              type = types.str;
              description = "Path to agenix secret file (e.g., 'secrets/iscsi/password')";
              default = "secrets/iscsi/password";
            };
            passwordAgeFile = mkOption {
              type = types.path;
              description = "Path to the .age file containing CHAP password";
              example = "../../secrets/iscsi/password.age";
            };
          };
        }
      );
      default = null;
      description = "Optional CHAP authentication credentials";
    };

    mounts = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            target = mkOption {
              type = types.str;
              description = "iSCSI target IQN to mount (e.g. iqn.2000-01.com.synology:steam)";
            };
            device = mkOption {
              type = types.str;
              description = "Block device path after iSCSI login (e.g. /dev/sda)";
            };
            mountPoint = mkOption {
              type = types.str;
              description = "Where to mount the iSCSI volume (e.g. /Users/mitch/.local/share/Steam)";
            };
            fsType = mkOption {
              type = types.str;
              default = "xfs";
              description = "Filesystem type for the iSCSI volume";
            };
            options = mkOption {
              type = types.listOf types.str;
              default = [
                "_netdev"
                "nofail"
              ];
              description = "Mount options";
            };
          };
        }
      );
      default = [ ];
      description = "List of iSCSI volumes to mount after login";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment = {
        systemPackages = with pkgs; [
          openiscsi
          lsscsi
        ];

        shellAliases = {
          iscsi-status = "systemctl status iscsid.service";
          iscsi-sessions = "iscsiadm -m session";
          iscsi-nodes = "iscsiadm -m node";
          iscsi-discover = "iscsiadm -m discovery -t sendtargets -p ${cfg.portal}";
          iscsi-devices = "lsscsi";
          iscsi-login-all = "iscsiadm -m node --loginall=automatic";
        };
      };

      services.openiscsi = {
        enable = true;
        name = cfg.initiatorName;
      };

      systemd.services = {
        iscsi-discovery = {
          description = "iSCSI target discovery and login";
          after = [
            "network-online.target"
            "iscsid.service"
          ];
          wants = [ "network-online.target" ];
          # Anchor into the remote-fs ordering chain so mounts wait for us
          before = [ "remote-fs.target" ];
          wantedBy = [
            "multi-user.target"
            "remote-fs.target"
          ];
          serviceConfig = {
            # oneshot + RemainAfterExit cannot Restart; use simple so that
            # systemd will restart the service when the NAS is unreachable
            # at boot (e.g. the portal times out or iscsiadm exits non-zero).
            Type = "simple";
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = "10s";
            StartLimitBurst = 10;
          };
          # Build the list of targets we actually care about at eval time so the
          # script never touches targets discovered on the portal that aren't
          # ours (e.g. Kubernetes PVC targets on the same Synology).
          script =
            let
              configuredTargets = map (m: m.target) cfg.mounts;
            in
            ''
              set -e

              # iscsiadm exit codes we need to treat as success:
              #   0  = OK
              #  15  = already logged in (ISCSI_ERR_SESS_EXISTS)
              iscsi_login() {
                local target="$1"
                local rc=0
                ${pkgs.openiscsi}/bin/iscsiadm -m node \
                  -T "$target" \
                  -p ${cfg.portal} \
                  --login || rc=$?
                # rc 15 = session already exists, that is fine
                if [ "$rc" -ne 0 ] && [ "$rc" -ne 15 ]; then
                  echo "iscsiadm login failed for $target with exit code $rc" >&2
                  return "$rc"
                fi
              }

              # Populate the node database for all targets on this portal.
              # Other targets (e.g. Kubernetes PVCs) are intentionally ignored
              # below — we only operate on the targets listed in cfg.mounts.
              ${pkgs.openiscsi}/bin/iscsiadm -m discovery -t sendtargets -p ${cfg.portal}

              ${optionalString (cfg.auth != null) ''
                for target in ${concatStringsSep " " configuredTargets}; do
                  echo "Configuring CHAP auth for target: $target"

                  ${pkgs.openiscsi}/bin/iscsiadm -m node \
                    -T "$target" \
                    -p ${cfg.portal} \
                    --op=update \
                    --name=node.session.auth.authmethod \
                    --value=CHAP

                  ${pkgs.openiscsi}/bin/iscsiadm -m node \
                    -T "$target" \
                    -p ${cfg.portal} \
                    --op=update \
                    --name=node.session.auth.username \
                    --value=${cfg.auth.username}

                  ${pkgs.openiscsi}/bin/iscsiadm -m node \
                    -T "$target" \
                    -p ${cfg.portal} \
                    --op=update \
                    --name=node.session.auth.password \
                    --value=$(${pkgs.coreutils}/bin/cat ${config.age.secrets."${cfg.auth.passwordSecretPath}".path})

                  # Set to automatic so iscsid reconnects after a restart
                  ${pkgs.openiscsi}/bin/iscsiadm -m node \
                    -T "$target" \
                    -p ${cfg.portal} \
                    --op=update \
                    --name=node.startup \
                    --value=automatic

                  iscsi_login "$target"
                done
              ''}

              ${optionalString (cfg.auth == null) ''
                for target in ${concatStringsSep " " configuredTargets}; do
                  echo "Setting automatic login for target: $target"

                  ${pkgs.openiscsi}/bin/iscsiadm -m node \
                    -T "$target" \
                    -p ${cfg.portal} \
                    --op=update \
                    --name=node.startup \
                    --value=automatic

                  iscsi_login "$target"
                done
              ''}
            '';
        };
      };

      # Use systemd.mounts instead of fileSystems so that NixOS writes a real
      # static .mount unit file into /etc/systemd/system/ in the store.
      # fileSystems with _netdev + nofail + x-systemd.* fstab options can end
      # up only in /etc/fstab and get generated at runtime by
      # systemd-fstab-generator under /run/systemd/generator/ — which means
      # the activation tool can't find the unit in the store path and dies.
      systemd.mounts = map (m: {
        what = m.device;
        where = m.mountPoint;
        type = m.fsType;
        # Keep the caller-supplied mount options (e.g. _netdev, nofail) as a
        # comma-separated string; ordering/deps are expressed as unit directives
        # below so we don't need x-systemd.* fstab hacks anymore.
        options = concatStringsSep "," m.options;
        after = [
          "network-online.target"
          "iscsid.service"
          "iscsi-discovery.service"
        ];
        requires = [ "iscsi-discovery.service" ];
        wants = [ "network-online.target" ];
        before = [ "remote-fs.target" ];
        wantedBy = [ "remote-fs.target" ];
      }) cfg.mounts;
    }

    # agenix secret for iSCSI password
    (mkIf (cfg.auth != null) {
      age.secrets."${cfg.auth.passwordSecretPath}" = {
        file = cfg.auth.passwordAgeFile;
        owner = "root";
        mode = "0400";
      };
    })
  ]);
}
