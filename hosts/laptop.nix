{ ... }: {
  # Since this is a laptop enable touchpad
  services.xserver.libinput.enable = true;

  # Laptop power management, reduce noisy af fan noise of this laptop
  # Ref: https://linrunner.de/tlp/settings/introduction.html
  services.tlp = {
    enable = true;
    settings = {
      CPU_MAX_PERF_ON_AC = 95;
      CPU_MAX_PERF_ON_BAT = 60;
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      ENERGY_PERF_POLICY_ON_AC = "powersave";
      ENERGY_PERF_POLICY_ON_BAT = "powersave";
      SCHED_POWERSAVE_ON_AC = "1";
      SCHED_POWERSAVE_ON_BAT = "1";
      TLP_DEFAULT_MODE = "BAT";
      TLP_PERSISTENT_DEFAULT = "1";
      START_CHARGE_THRESH_BAT0 = 50;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  # TODO: someday use this when the bat charge stuff works on more than lenovo
  # laptops, LAAAAAMEE
  # Run tlp fullcharge to fully charge when wanted
}
