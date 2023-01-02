{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.cluster;

  resources = builtins.toFile "resources.xml" ''
    <resources>
      <primitive class="ocf" id="cluvip" provider="heartbeat" type="IPaddr2">
        <instance_attributes id="cluvip-instance_attributes">
          <nvpair id="cluvip-instance_attributes-cidr_netmask" name="cidr_netmask" value="24"/>
          <nvpair id="cluvip-instance_attributes-ip" name="ip" value="10.10.10.200"/>
          <nvpair id="cluvip-instance_attributes-nic" name="nic" value="enp1s0"/>
        </instance_attributes>
        <operations>
          <op id="cluvip-monitor-interval-30s" interval="30s" name="monitor"/>
          <op id="cluvip-start-interval-0s" interval="0s" name="start" timeout="20s"/>
          <op id="cluvip-stop-interval-0s" interval="0s" name="stop" timeout="20s"/>
        </operations>
      </primitive>
      <primitive class="ocf" id="canaryvip" provider="heartbeat" type="IPaddr2">
        <instance_attributes id="canaryvip-instance_attributes">
          <nvpair id="canaryvip-instance_attributes-cidr_netmask" name="cidr_netmask" value="24"/>
          <nvpair id="canaryvip-instance_attributes-ip" name="ip" value="10.10.10.254"/>
          <nvpair id="canaryvip-instance_attributes-nic" name="nic" value="enp1s0"/>
        </instance_attributes>
        <operations>
          <op id="canaryvip-monitor-interval-30s" interval="30s" name="monitor"/>
          <op id="canaryvip-start-interval-0s" interval="0s" name="start" timeout="20s"/>
          <op id="canaryvip-stop-interval-0s" interval="0s" name="stop" timeout="20s"/>
        </operations>
      </primitive>
      <primitive id="cat" class="systemd" type="canary-cat">
        <operations>
          <op id="stop-cat" name="start" interval="0" timeout="1s"/>
          <op id="start-cat" name="start" interval="0" timeout="1s"/>
          <op id="monitor-cat" name="monitor" interval="1s" timeout="1s"/>
        </operations>
      </primitive>
    </resources>
  '';

  # If we're updating resources have to kill constraints then can add new resources
  constraintsEmpty = builtins.toFile "constraints.xml" ''
    <constraints>
    </constraints>
  '';

  constraints = builtins.toFile "constraints.xml" ''
    <constraints>
      <rsc_order id="order-1" first="canaryvip" then="cat" kind="Mandatory"/>
      <rsc_colocation id="colocate" rsc="canaryvip" with-rsc="cat" score="INFINITY"/>
    </constraints>
  '';

  systemdSetupCorosync = pkgs.writeScriptBin "setup_corosync" ''
        #${pkgs.runtimeShell}
        set -eux
        AWK=${pkgs.gawk}/bin/awk
        PATH=$PATH:${pkgs.pacemaker}/bin

        . ${../../static/src/lib.sh}

        lim=5
        rsleep $lim
        # Since I have no stonith device, have to run in super cereal scary mode
        crm_attribute --type crm_config --name stonith-enabled --update false
    #    crm_attribute --type crm_config --name no-quorum-policy --update ignore
        crm_attribute --type crm_config --name no-quorum-policy --delete
        rsleep $lim
        cibadmin --replace --scope constraints --xml-file ${constraintsEmpty}
        cibadmin --replace --scope resources --xml-file ${resources}
        cibadmin --replace --scope constraints --xml-file ${constraints}
  '';

  # For firewall setup
  pacemakerTcpPorts = [ 2224 3121 5403 ];
  pacemakerUdpPorts = [ 5404 5405 ];

  # For portmapper
  glusterTcpPorts = [ 111 2049 4045 20048 ];
  glusterUdpPorts = [ 111 2049 4045 ];

  # combined server+client ports
  glusterTcpPortRanges = [
    { from = 24007; to = 24008; }
    { from = 38465; to = 38467; }
    # { from = 49152; to = 49170; }
    { from = 49152; to = 60999; }
  ];
in
{
  options.services.role.cluster = {
    enable = mkEnableOption "Designate if this is ha cluster server member and any dependent resources";

    # TODO: port this into the corosync options
    authKey = mkOption {
      default = "testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest";
      type = types.str;
      example = literalExpression ''
        some128characterstring
      '';
      description = lib.mkDoc ''
        Specify the corosync auth key in use for the cluster for node to node communication.
      '';
    };
  };

  config = mkIf cfg.enable {
    networking = {
      firewall = {
        allowedTCPPortRanges = [ ] ++ glusterTcpPortRanges;
        allowedTCPPorts = [ ] ++ pacemakerTcpPorts ++ glusterTcpPorts;
        allowedUDPPorts = [ ] ++ pacemakerUdpPorts ++ glusterUdpPorts;
      };
    };

    # Corosync/pacemaker setup, only using pacemaker to do:
    # - Plumb an ip and then start a systemd resource
    # - Start a systemd resource
    #
    # The systemd resources have all the knowledge needed to do the rest.
    # pacemaker is kept stupid intentionally outside of knowing if/when to tie
    # an ip to a systemd resource.
    services.corosync = {
      enable = true;
      clusterName = "clu";
      nodelist = [
        {
          nodeid = 1;
          name = "cl1";
          ring_addrs = [ "10.10.10.6" ];
        }
        {
          nodeid = 2;
          name = "cl2";
          ring_addrs = [ "10.10.10.7" ];
        }
        {
          nodeid = 3;
          name = "cl3";
          ring_addrs = [ "10.10.10.8" ];
        }
      ];
    };

    environment.etc."corosync/authkey" = {
      source = builtins.toFile "authkey" cfg.authKey;
      mode = "0400";
    };

    services.pacemaker.enable = true;

    # Here to run/setup corosync after it boots, runs per node but thats OK, it
    # just replaces resources with what we configure here so its idempotent to
    # run multiple times. TODO: Find a better way, some activation script
    # probably be a better spot to stick this junk.
    systemd.services.setup_corosync = {
      enable = true;
      after = [ "corosync.service" "pacemaker.service" ];
      serviceConfig.Type = "oneshot";
      script = "${systemdSetupCorosync}/bin/setup_corosync";
    };

    # yeeted from the tests for a systemd resource to test with, plumbs to the
    # canary ip address so I can validate the cluster setup works
    systemd.services.canary-cat = {
      description = "netcat canary resource";
      # serviceConfig.ExecStart = "${pkgs.netcat}/bin/nc -k -p 1234 -4 -l discard";
      serviceConfig.ExecStart = "${pkgs.netcat}/bin/nc -l discard";
    };

    # Gluster setup
    #
    # Using this for "keep a directory of crap in sync amongst all 3 nodes"
    #
    # That for now encompasses simple crap like:
    # nginx cache for nix derivations
    # FUTURE: dns lease data for dnsmasq
    #
    # Structure is simply
    # environment.systemPackages = [ pkgs.glusterfs ];

    services.glusterfs = {
      enable = true;
      logLevel = "DEBUG";
    };

    systemd.services.glusterd = {
      path = [ pkgs.nettools ];
      serviceConfig = {
        preStart =
          ''
            set -eux
            PATH=$PATH:${pkgs.zfs}/bin

            # for x in zroot/data/gluster zroot/data; do
            #   zfs destroy $x
            # done

            zfs list zroot/data || zfs create zroot/data -o compression=zstd -o mountpoint=/data
            zfs list zroot/data/gluster || zfs create zroot/data/gluster -o compression=zstd
          '';
        postStart = ''
          set -eux
          PATH=$PATH:${pkgs.glusterfs}/bin:${pkgs.gawk}/bin

          . ${../../static/src/lib.sh}

          us gluster peer status

          for node in cl1.home.arpa cl2.home.arpa cl3.home.arpa; do
            gluster peer probe $node
          done

          install -dm755 /data/gluster/brick

          if [ "$(uname -n)" = "cl1" ]; then
            if ! gluster volume list | grep data-gluster; then
              gluster volume create data-gluster replica 3 cl1.home.arpa:/data/gluster/brick cl2.home.arpa:/data/gluster/brick cl3.home.arpa:/data/gluster/brick
              gluster volume start data-gluster
            fi
          fi
        '';
      };
    };

    # Note the system here is only used at initial mount, once mounted that node
    # can go down. So for simplicity, use the first node for this.
    systemd.mounts = [{
      wantedBy = [ "multi-user.target" ];
      what = "cluster.home.arpa:/data-gluster";
      where = "/gluster";
      description = "/gluster client mountpoint";
      after = [ "glusterd.service" ];
      requires = [ "glusterd.service" ];
      type = "glusterfs";
      # Note if we hit a timeout its likely due to misconfiguration
      mountConfig.TimeoutSec = "10s";
    }];
  };
}
