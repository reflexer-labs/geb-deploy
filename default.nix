{ pkgsSrc ? (import ./nix/pkgs.nix {}).pkgsSrc
, pkgs ? (import ./nix/pkgs.nix { inherit pkgsSrc; }).pkgs
, doCheck ? false
}: with pkgs;

let
  inherit (callPackage ./nix/dapp.nix {}) specs package;

  this = package (specs.this // {
    name = "geb-deploy";
    inherit doCheck;
    solcFlags = "--metadata";
  });

  this-optimize = package (specs.this // {
    name = "geb-deploy-optimized";
    inherit doCheck;
    solcFlags = "--optimize --metadata";
  });

  mkScripts = { regex, name, solidityPackages }: makerScriptPackage {
    inherit name solidityPackages;
    src = lib.sourceByRegex ./bin (regex ++ [ ".*lib.*" ]);
    extraBins = [ git ];
    scriptEnv = {
      SKIP_BUILD = true;
    };
  };

  optimized = mkScripts {
    name = "geb-deploy-optimized";
    regex = [ "deploy-core" ];
    solidityPackages = [ this-optimize ];
  };

  nonOptimized = mkScripts {
    name = "geb-deploy";
    regex = [ "deploy-contract-deployer" "deploy-collateral-type.*" ];
    solidityPackages = [ this ];
  };
in symlinkJoin {
  name = "geb-deploy-both";
  paths = [ optimized nonOptimized ];
}
