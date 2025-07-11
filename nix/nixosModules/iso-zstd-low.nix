{ lib, ... }:
{
  # For max compression (takes way longer to build an image tho)
  #
  # Compression levels: https://github.com/facebook/zstd/blob/dev/lib/compress/clevels.h#L25
  #
  # Use 5 for testing, 19 for keeping iso size down on a chonky system
  #
  # Rough size diff with current test data:
  # level 5
  # 6.5G    /nix/store/j82paybcnppn5s9g9pc0pih6f3jknaxx-nixos-24.11.20250408.a62d20d-x86_64-linux.iso/iso/nixos-24.11.20250408.a62d20d-x86_64-linux.iso
  # level 19
  # 6.2G    /nix/store/66az8g3g98crb1zx7wnnkpcjvaanayfa-nixos-24.11.20250408.a62d20d-x86_64-linux.iso/iso/nixos-24.11.20250408.a62d20d-x86_64-linux.iso
  isoImage.squashfsCompression = "zstd -Xcompression-level 5";
}
