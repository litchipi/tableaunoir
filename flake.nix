{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs: with inputs; flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };

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
  in {
    apps.install = mkScript "install-node-deps" ''
      export NODE_ENV=production
      npm install --include dev
      rg -n "usr/bin/env node" -l node_modules/ | xargs sed -i "s+/usr/bin/env node+${pkgs.nodejs}/bin/node+g"
      rg -n "usr/bin/env bash" -l node_modules/ | xargs sed -i "s+/usr/bin/env bash+${pkgs.bash}/bin/bash+g"
      rg -n "usr/bin/env sh" -l node_modules/ | xargs sed -i "s+/usr/bin/env sh+${pkgs.bash}/bin/bash+g"
    '';

    apps.build = mkScript "build-pkg" ''
      export NODE_ENV=production
      npm run build
    '';

    apps.lint = mkScript "lint-pkg" ''
      export NODE_ENV=development
      npm run lint | tee dist/status.txt
    '';
  });
}
