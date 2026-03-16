{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs: with inputs; flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
    lib = pkgs.lib;

    mkScript = name: text: let
      app = pkgs.writeShellApplication {
        inherit name text;
        runtimeInputs = [
          pkgs.nodejs
          pkgs.ripgrep
          pkgs.gnused
          pkgs.findutils
        ];
      };
    in { type = "app"; program = "${app}/bin/${name}"; };

    nodeCache = pkgs.fetchNpmDeps {
      src = ./.;
      hash = "sha256-LZjFeXeZdnCzLSPg+28hNqyJGGAb+ZXEyGl7lTCCeZE=";
    };

    psb = what: pkg: "rg -n \"usr/bin/env ${what}\" -l node_modules/ | xargs sed -i \"s+/usr/bin/env ${what}+${lib.getExe pkg}+g\" 2>/dev/null || echo \"No shebang to patch for ${what}\"";

    build = type: ''
      export NODE_ENV=${type}
      npm run build
    '';
  in {
    apps.default = mkScript "start-pkg" ''
      ${build "production"}
      ${pkgs.electron}/bin/electron ./mainElectron.js
    '';

    apps.test = mkScript "test-pkg" ''
      ${build "development"}
      ${pkgs.electron}/bin/electron ./mainElectron.js
    '';

    apps.install = mkScript "install" ''
      npm ci --cache ${nodeCache}
      npm install --include dev
      ${psb "node" pkgs.nodejs}
      ${psb "bash" pkgs.bash}
      ${psb "sh" pkgs.bash}
    '';

    apps.build = mkScript "build-pkg" (build "production");
    apps.lint = mkScript "lint-pkg" ''
      export NODE_ENV=development
      npm run lint | tee dist/status.txt
    '';
  });
}
