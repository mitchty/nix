{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.role.cluster;

  resources = builtins.toFile "resources.xml" ''
    <resources>
      <!-- cluster.home.arpa vip used for cluster-y things not general apps -->
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
      <!-- cache.cluster.home.arpa vip used for cluster-y things not general apps -->
      <primitive class="ocf" id="cachevip" provider="heartbeat" type="IPaddr2">
        <instance_attributes id="cachevip-instance_attributes">
          <nvpair id="cachevip-instance_attributes-cidr_netmask" name="cidr_netmask" value="24"/>
          <nvpair id="cachevip-instance_attributes-ip" name="ip" value="10.10.10.201"/>
          <nvpair id="cachevip-instance_attributes-nic" name="nic" value="enp1s0"/>
        </instance_attributes>
        <operations>
          <op id="cachevip-monitor-interval-30s" interval="30s" name="monitor"/>
          <op id="cachevip-start-interval-0s" interval="0s" name="start" timeout="20s"/>
          <op id="cachevip-stop-interval-0s" interval="0s" name="stop" timeout="20s"/>
        </operations>
      </primitive>
      <!-- nas.cluster.home.arpa vip for mounting /gluster/nas -->
      <primitive class="ocf" id="nasvip" provider="heartbeat" type="IPaddr2">
        <instance_attributes id="nasvip-instance_attributes">
          <nvpair id="nasvip-instance_attributes-cidr_netmask" name="cidr_netmask" value="24"/>
          <nvpair id="nasvip-instance_attributes-ip" name="ip" value="10.10.10.202"/>
          <nvpair id="nasvip-instance_attributes-nic" name="nic" value="enp1s0"/>
        </instance_attributes>
        <operations>
          <op id="nasvip-monitor-interval-30s" interval="30s" name="monitor"/>
          <op id="nasvip-start-interval-0s" interval="0s" name="start" timeout="20s"/>
          <op id="nasvip-stop-interval-0s" interval="0s" name="stop" timeout="20s"/>
        </operations>
      </primitive>
      <!-- canary.home.arpa vip for use with netcat, not really useful should delete -->
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
          <op id="stop-cat" name="stop" interval="0" timeout="1s"/>
          <op id="start-cat" name="start" interval="0" timeout="1s"/>
          <op id="monitor-cat" name="monitor" interval="1s" timeout="1s"/>
        </operations>
      </primitive>
      <primitive id="samba" class="systemd" type="samba-smbd">
        <operations>
          <op id="stop-samba" name="stop" interval="0" timeout="10s"/>
          <op id="start-samba" name="start" interval="0" timeout="1s"/>
          <op id="monitor-samba" name="monitor" interval="1s" timeout="1s"/>
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
      <rsc_order id="order-cat" first="canaryvip" then="cat" kind="Mandatory"/>
      <rsc_colocation id="colocate-cat" rsc="canaryvip" with-rsc="cat" score="INFINITY"/>
      <rsc_order id="order-samba" first="nasvip" then="samba" kind="Mandatory"/>
      <rsc_colocation id="colocate-samba" rsc="nasvip" with-rsc="samba" score="INFINITY"/>
    </constraints>
  '';

  pacemakerTrampoline = pkgs.writeScriptBin "pacemaker-trampoline" ''#!${pkgs.runtimeShell}
    set -eux
    AWK=${pkgs.gawk}/bin/awk
    PATH=$PATH:${pkgs.pacemaker}/bin

    . ${../../static/src/lib.sh}

    if [ "cl1" = "$(uname -n)" ]; then
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
    fi

    # then sleeeeeeeeep!
    while true; do
      sleep 30d
    done
  '';

  sambaTrampoline = pkgs.writeScriptBin "samba-trampoline" ''#!${pkgs.runtimeShell}
    set -eux

    install -dm755 /gluster/nas

    priv=/var/lib/samba/private
    install -dm755 $priv
    install -m600 /gluster/cfg/nas/passdb.tdb $priv/passwd.tdb
    install -m600 /gluster/cfg/nas/netlogon_creds_cli.tdb $priv/netlogon_creds_cli.tdb
    install -m600 /gluster/cfg/nas/secrets.tdb $priv/secrets.tdb

    # then sleeeeeeeeep!
    while true; do
      sleep 30d
    done
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

  # for samba
  sambaTcpPorts = [ 445 139 ];
  sambaUdpPorts = [ 137 138 ];
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
        allowedTCPPorts = [ ] ++ pacemakerTcpPorts ++ glusterTcpPorts ++ sambaTcpPorts;
        allowedUDPPorts = [ ] ++ pacemakerUdpPorts ++ glusterUdpPorts ++ sambaUdpPorts;
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

    # Here to work around not being able to always overrride postStart or
    # ExecPostStart in pacemaker, we set this up that *other* systemd services
    # can require it to have ran. This is setup so that only the first node
    # updates the pacemaker configuration when needed.
    systemd.services.pacemaker-trampoline = {
      enable = true;
      after = [ "corosync.service" "pacemaker.service" ];
      serviceConfig.ExecStart = "${pacemakerTrampoline}/bin/pacemaker-trampoline";
    };

    # yeeted from the tests for a systemd resource to test with, plumbs to the
    # canary ip address so I can validate the cluster setup works
    systemd.services.canary-cat = {
      description = "netcat canary resource";
      # serviceConfig.ExecStart = "${pkgs.netcat}/bin/nc -k -p 1234 -4 -l discard";
      serviceConfig.ExecStart = "${pkgs.netcat}/bin/nc -l discard";
    };

    # Gluster setup (for comparing against seaweedfs) want to see how nfs/smb on
    # top of this works (or not)
    #
    # Using this for "keep a directory of crap in sync amongst all 3 nodes"
    #
    # That for now encompasses simple crap like:
    # nginx cache for nix derivations
    # FUTURE: dns lease data for dnsmasq
    #
    # Structure is simply
    # environment.systemPackages = [ pkgs.glusterfs ];

    services.glusterfs.enable = true;

    systemd.services.glusterd = {
      path = [ pkgs.nettools ];
      preStart = ''
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

        if [ "cl1" = "$(uname -n)" ]; then
          if ! gluster volume list | grep data-gluster; then
            gluster volume create data-gluster replica 3 cl1.home.arpa:/data/gluster/brick cl2.home.arpa:/data/gluster/brick cl3.home.arpa:/data/gluster/brick
            gluster volume start data-gluster
          fi
        fi
      '';
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

    systemd.services.samba-trampoline = {
      enable = true;
      requires = [ "gluster.mount" "pacemaker-trampoline.service" ];
      serviceConfig.ExecStart = "${sambaTrampoline}/bin/samba-trampoline";
    };

    services.samba = {
      enable = true;
      enableNmbd = false;
      openFirewall = true;
      enableWinbindd = false;
      securityType = "user";
      extraConfig = ''
        log level = 3
        interfaces = 10.10.10.202
        workgroup = WORKGROUP
        server role = standalone server
        dns proxy = no
        allow insecure wide links = yes
        vfs objects = catia fruit streams_xattr
        pam password change = yes
        map to guest = bad user
        usershare allow guests = yes
        create mask = 0664
        force create mode = 0664
        directory mask = 0775
        force directory mode = 0775
        load printers = no
        printing = bsd
        printcap name = /dev/null
        disable spoolss = yes
        strict locking = no
        aio read size = 0
        aio write size = 0
        vfs objects = catia fruit streams_xattr
        # Security
        client ipc max protocol = SMB3
        client ipc min protocol = SMB2_10
        client max protocol = SMB3
        client min protocol = SMB2_10
        server max protocol = SMB3
        server min protocol = SMB2_10
        # Time Machine
        fruit:delete_empty_adfiles = yes
        fruit:time machine = yes
        fruit:veto_appledouble = no
        fruit:wipe_intentionally_left_blank_rfork = yes
        server string = nas.cluster.home.arpa
        netbios name = nas.cluster.home.arpa
        guest account = nobody
        map to guest = bad user
        logging = systemd
      '';
      shares = {
        nas = {
          path = "/gluster/nas";
          browseable = "yes";
          "valid users" = "mitch";
          "read only" = "no";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "veto files" = "/.apdisk/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/";
          "delete veto files" = "yes";
          "wide links" = "yes";
        };
      };
    };

    # Ok so this is jank af but we have to 'enable' the samba module, so that
    # the systemd service is define and not masked and wants to run. BUT if we
    # set enable = mkForce false at the systemd level that gets the service
    # masked and can't be started by pacemaker. Which is annoying af. However,
    # if we force wantedBy to be empty, systemd won't start the service. Which
    # means pacemaker can then be the arbiter of starting it. Yeah this whole
    # setup is hokey/janky but for a minimal "ha" setup its *fine*.
    systemd.services.samba-smbd = {
      wantedBy = lib.mkForce [ ];
      requires = [ "samba-trampoline.service" ];
    };
  };
  #  services.samba.openFirewall = true;
  # networking.firewall.enable = true;
  #  networking.firewall.allowPing = true;
}
