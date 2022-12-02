{ ... }: {
  # TODO: nixos 22.11 says no to both tlp and powermanagement, figure it out or
  # if it matters.

  # services.tlp = {
  #   enable = true;
  #   settings = {
  #     CPU_SCALING_GOVERNOR_ON_AC = "powersave";
  #     ENERGY_PERF_POLICY_ON_AC = "powersave";
  #     SCHED_POWERSAVE_ON_AC = "1";
  #     TLP_PERSISTENT_DEFAULT = "1";
  #   };
  # };

  services.upower.enable = true;
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
}
