{ config, lib, pkgs, ... }:

with lib;

let

  uid = config.ids.uids.gpsd;
  gid = config.ids.gids.gpsd;
  cfg = config.services.gpsd;

in

{

  ###### interface

  options = {

    services.gpsd = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Whether to enable `gpsd', a GPS service daemon.
        '';
      };

      device = mkOption {
        type = types.str;
        default = "/dev/ttyUSB0";
        description = lib.mdDoc ''
          A device may be a local serial device for GPS input, or a URL of the form:
               `[{dgpsip|ntrip}://][user:passwd@]host[:port][/stream]`
          in which case it specifies an input source for DGPS or ntrip data.
        '';
      };

      readonly = mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc ''
          Whether to enable the broken-device-safety, otherwise
          known as read-only mode.  Some popular bluetooth and USB
          receivers lock up or become totally inaccessible when
          probed or reconfigured.  This switch prevents gpsd from
          writing to a receiver.  This means that gpsd cannot
          configure the receiver for optimal performance, but it
          also means that gpsd cannot break the receiver.  A better
          solution would be for Bluetooth to not be so fragile.  A
          platform independent method to identify
          serial-over-Bluetooth devices would also be nice.
        '';
      };

      nowait = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          don't wait for client connects to poll GPS
        '';
      };

      port = mkOption {
        type = types.port;
        default = 2947;
        description = lib.mdDoc ''
          The port where to listen for TCP connections.
        '';
      };

      debugLevel = mkOption {
        type = types.int;
        default = 0;
        description = lib.mdDoc ''
          The debugging level.
        '';
      };

      listenany = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Listen on all addresses rather than just loopback.
        '';
      };

    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    users.users.gpsd =
      { inherit uid;
        group = "gpsd";
        description = "gpsd daemon user";
        home = "/var/empty";
      };

    users.groups.gpsd = { inherit gid; };

    systemd.services.gpsd = {
      description = "GPSD daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "forking";
        ExecStart = ''
          ${pkgs.gpsd}/sbin/gpsd -D "${toString cfg.debugLevel}"  \
            -S "${toString cfg.port}"                             \
            ${optionalString cfg.readonly "-b"}                   \
            ${optionalString cfg.nowait "-n"}                     \
            ${optionalString cfg.listenany "-G"}                  \
            "${cfg.device}"
        '';
      };
    };

  };

}
