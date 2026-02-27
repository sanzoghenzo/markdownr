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
          android_sdk.accept_license = true;
        };
        androidEnv = pkgs.androidenv.override { licenseAccepted = true; };
        androidComposition = androidEnv.composeAndroidPackages {
          # cmdLineToolsVersion = "8.0";
          # platformToolsVersion = "34.0.4";
          # buildToolsVersions = [ "30.0.3" "33.0.2" "34.0.0" ];
          # platformVersions = [ "28" "31" "32" "33" "34" ];
          abiVersions = [ "x86_64" ];
          includeNDK = false;
          includeSystemImages = true;
          systemImageTypes = [ "google_apis" "google_apis_playstore" ];
          # includeEmulator = true;
          useGoogleAPIs = true;
          extraLicenses = [
            "android-googletv-license"
            "android-sdk-arm-dbt-license"
            "android-sdk-license"
            "android-sdk-preview-license"
            "google-gdk-license"
            "intel-android-extra-license"
            "intel-android-sysimage-license"
            "mips-android-sysimage-license"
          ];
        };
        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell = with pkgs; mkShell rec {
          ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          JAVA_HOME = jdk11.home;
          FLUTTER_ROOT = flutter;
          DART_ROOT = "${flutter}/bin/cache/dart-sdk";
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/33.0.2/aapt2";
          QT_QPA_PLATFORM = "wayland;xcb"; # emulator related: try using wayland, otherwise fall back to X.
          # NB: due to the emulator's bundled qt version, it currently does not start with QT_QPA_PLATFORM="wayland".
          # Maybe one day this will be supported.
          buildInputs = [
            androidSdk
            flutter
            qemu_kvm
            gradle
            jdk11
          ];
          # emulator related: vulkan-loader and libGL shared libs are necessary for hardware decoding
          LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [vulkan-loader libGL]}";
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
