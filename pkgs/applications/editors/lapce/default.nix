{ lib
, stdenv
, fetchFromGitHub
, gitUpdater
, rustPlatform
, cmake
, pkg-config
, perl
, fontconfig
, copyDesktopItems
, makeDesktopItem
, glib
, gtk3
, openssl
, libobjc
, Security
, CoreServices
, ApplicationServices
, Carbon
, AppKit
, wrapGAppsHook
, gobject-introspection
}:

rustPlatform.buildRustPackage rec {
  pname = "lapce";
  version = "0.2.4";

  src = fetchFromGitHub {
    owner = "lapce";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-A0HeZB022GFrZFkdcSuzUmNBxxZHKCcqtTUh5MbGsEg=";
  };

  cargoSha256 = "sha256-XracOWjkFZiv5bc3Xfm8sRta6CdO5rjrYAzRs3JT0rc=";

  nativeBuildInputs = [
    cmake
    pkg-config
    perl
    copyDesktopItems
    wrapGAppsHook # FIX: No GSettings schemas are installed on the system
    gobject-introspection
  ];

  # Get openssl-sys to use pkg-config
  OPENSSL_NO_VENDOR = 1;

  buildInputs = [
    glib
    gtk3
    openssl
  ] ++ lib.optionals stdenv.isLinux [
    fontconfig
  ] ++ lib.optionals stdenv.isDarwin [
    libobjc
    Security
    CoreServices
    ApplicationServices
    Carbon
    AppKit
  ];

  postInstall = ''
    install -Dm0644 $src/extra/images/logo.svg $out/share/icons/hicolor/scalable/apps/lapce.svg
  '';

  desktopItems = [ (makeDesktopItem {
    name = "lapce";
    exec = "lapce %F";
    icon = "lapce";
    desktopName = "Lapce";
    comment = meta.description;
    genericName = "Code Editor";
    categories = [ "Development" "Utility" "TextEditor" ];
  }) ];

  passthru.updateScript = gitUpdater {
    rev-prefix = "v";
  };

  meta = with lib; {
    description = "Lightning-fast and Powerful Code Editor written in Rust";
    homepage = "https://github.com/lapce/lapce";
    license = with licenses; [ asl20 ];
    maintainers = with maintainers; [ elliot ];
  };
}
