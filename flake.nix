{
  description = "Flutter environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.android_sdk.accept_license = true;
        };
        buildToolsVersion = "35.0.0";
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          includeEmulator = false;
          includeNDK = "if-supported";
          includeSystemImages = "if-supported";
          buildToolsVersions = [ buildToolsVersion ];
          cmakeVersions = [ "3.22.1" ];
          platformVersions = [ "34" "35" "36" ];
          ndkVersions = [ "28.2.13676358" ];
          platformToolsVersion = "36.0.2";
        };
        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell = with pkgs; mkShell rec {
          buildInputs = [
            androidSdk
            flutter
            jdk17
            lcov
            go-task
            qemu_kvm
          ];

          ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
          JAVA_HOME = jdk17;
          FLUTTER_ROOT = flutter;
          DART_ROOT = "${flutter}/bin/cache/dart-sdk";
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_HOME}/build-tools/${buildToolsVersion}/aapt2";
          _JAVA_AWT_WM_NONREPARENTING="1";
          # Globally installed packages, which are installed through `dart pub global activate package_name`,
          # are located in the `$PUB_CACHE/bin` directory.
          shellHook = ''
            if [ -z "$PUB_CACHE" ]; then
              export PATH="$PATH:$HOME/.pub-cache/bin"
            else
              export PATH="$PATH:$PUB_CACHE/bin"
            fi
          '';
        };
      }
    );
}
