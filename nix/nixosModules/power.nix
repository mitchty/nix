{ lib, ... }:
{
  # General power management settings to reduce how many Joules are used
  services = {
    auto-cpufreq.enable = true;
    thermald.enable = true;
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
    # power, performance, ondemand, future me will do more for the laptop
    cpuFreqGovernor = "schedutil";
  };

  # The system76 stuff helps with changing linux scheduling heuristics
  # without too much perf impact so just use it.
  hardware.system76.power-daemon.enable = true;
  services.system76-scheduler.enable = true;
}
