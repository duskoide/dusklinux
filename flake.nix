{
  description = "dusklinux — minimal Alpine-based distro with a Nix-managed desktop layer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri: scrollable-tiling Wayland compositor.
    # Using the upstream flake for latest builds + the community HM module.
    niri = {
      url = "github:niri-wm/niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DankMaterialShell — desktop shell built on quickshell (Qt6/QML).
    # Provides packages + a Home Manager module.
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # herdr — personal tooling, carried over from the existing HM config.
    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      niri,
      dms,
      herdr,
      ...
    }:
    let
      system = "x86_64-linux";
      username = "pn";
    in
    {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {
          inherit herdr;
          dmsPackage = dms.packages.${system}.default;
        };
        modules = [
          ./home/home.nix
          ./home/shell.nix
          niri.homeManagerModules.default
          dms.homeManagerModules.default
        ];
      };
    };
}
