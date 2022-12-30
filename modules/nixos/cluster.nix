{ config, lib, pkgs, ... }:

with lib;

# Notes, note largely just replicated what the unit test in nixos/nixpkgs had...:
# on cl1 ran (no stonith device): crm_attribute -t crm_config -n stonith-enabled -v false
# on cl1 ran: cibadmin --replace --scope resources --xml-file /etc/clu-resources.xml
# sudo crm_resource -r cat --locate

let
  cfg = config.services.role.cluster;
in
{
  options.services.role.cluster = {
    enable = mkEnableOption "Designate if something isn't an ha cluster server";
  };

  config = mkIf cfg.enable {
    networking = {
      firewall = {
        allowedTCPPorts = [ 2224 3121 5403 ];
        allowedUDPPorts = [ 5404 5405 ];
      };
    };
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
    # Look, if this is that critical I shouldn't share it cause if people are in
    # my network they can muck with cluster resources... I'm already compromised
    # physically or otherwise.
    environment.etc."corosync/authkey" = {
      source = builtins.toFile "authkey"
        "testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest";
      mode = "0400";
    };

    environment.etc."corosync/resources.xml" = {
      source = builtins.toFile "resources.xml" ''
        <resources>
          <primitive class="ocf" id="VIP" provider="heartbeat" type="IPaddr2">
            <instance_attributes id="VIP-instance_attributes">
              <nvpair id="VIP-instance_attributes-cidr_netmask" name="cidr_netmask" value="24"/>
              <nvpair id="VIP-instance_attributes-ip" name="ip" value="10.10.10.200"/>
              <nvpair id="VIP-instance_attributes-nic" name="nic" value="enp1s0"/>
            </instance_attributes>
            <operations>
              <op id="VIP-monitor-interval-30s" interval="30s" name="monitor"/>
              <op id="VIP-start-interval-0s" interval="0s" name="start" timeout="20s"/>
              <op id="VIP-stop-interval-0s" interval="0s" name="stop" timeout="20s"/>
            </operations>
          </primitive>
          <primitive id="cat" class="systemd" type="ha-cat">
            <operations>
              <op id="stop-cat" name="start" interval="0" timeout="1s"/>
              <op id="start-cat" name="start" interval="0" timeout="1s"/>
              <op id="monitor-cat" name="monitor" interval="1s" timeout="1s"/>
            </operations>
          </primitive>
        </resources>
      '';
      mode = "0400";
    };

    # So we can use the ocf ha agents
    systemd.packages = [ pkgs.ocf-resource-agents pkgs.iproute2 ];
    environment.systemPackages = [ pkgs.ocf-resource-agents pkgs.iproute2 ];

    services.pacemaker.enable = true;


    # TODO: Should this get upstreamed? Just restarting the service right now
    # results in pacemaker/corosync being broken which is seemingly pointless
    # for a cluster.
    systemd.services.pacemaker.serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/chown -R hacluster:pacemaker /var/lib/pacemaker";
    systemd.services.pacemaker.serviceConfig.ExecStartPost = "${pkgs.coreutils}/bin/chown -R hacluster:pacemaker /var/lib/pacemaker";
    systemd.services.pacemaker.path = [ pkgs.ocf-resource-agents pkgs.iproute2 ];

    # yeeted from the tests for a systemd resource
    systemd.services.ha-cat = {
      description = "Highly available netcat";
      serviceConfig.ExecStart = "${pkgs.netcat}/bin/nc -l discard";
    };
  };
}
