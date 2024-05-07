{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.stratum.hardware;
in {
  imports = [
    ./aarch64.nix
  ];

  config = mkIf (cfg.enable && cfg.raspberry-pi.enable) {
    stratum.hardware.aarch64.enable = true;

    environment.systemPackages = with pkgs; [
      libraspberrypi
      raspberrypi-eeprom
    ];

    hardware.deviceTree = {
      enable = true;
      filter = "*-rpi-*.dtb";
      overlays = [
        {
          name = "rpi4-pps-gpio-overlay";
          dtsText = ''
          /dts-v1/;
          /plugin/;

          / {
            compatible = "brcm,bcm2711";
            fragment@0 {
              target-path = "/";
              __overlay__ {
                pps: pps@12 {
                  compatible = "pps-gpio";
                  pinctrl-names = "default";
                  pinctrl-0 = <&pps_pins>;
                  gpios = <&gpio 18 0>;
                  status = "okay";
                };
              };
            };

            fragment@1 {
              target = <&gpio>;
              __overlay__ {
                pps_pins: pps_pins@12 {
                  brcm,pins =     <18>;
                  brcm,function = <0>;    // in
                  brcm,pull =     <0>;    // off
                };
              };
            };

            __overrides__ {
              gpiopin = <&pps>,"gpios:4",
                  <&pps>,"reg:0",
                  <&pps_pins>,"brcm,pins:0",
                  <&pps_pins>,"reg:0";
              assert_falling_edge = <&pps>,"assert-falling-edge?";
              capture_clear = <&pps>,"capture-clear?";
              pull = <&pps_pins>,"brcm,pull:0";
            };
          };
          '';
        }
        {
          name = "disable-bt";
          dtboFile = ../../overlays/disable-bt.dtbo;
        }
        {
          name = "i2c-rtc";
          dtboFile = ../../overlays/i2c-rtc.dtbo;
        }
      ];
    };
  };
}
