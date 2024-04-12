# Stratum

NixOS + Raspberry Pi + GNSS (GPS) receiver = Stratum

Easily customizable images for the Raspberry Pi make running a highly accurate
[stratum 1][ntporg-stratum-1] time server accessible and practical. All you
need is a Raspberry Pi, a cheap GNSS receiver and some time (hehehe) to [get
started](#getting-started).

[ntporg-stratum-1]: https://www.ntp.org/ntpfaq/ntp-s-algo/#5115-what-is-a-stratum-1-server "What is a stratum 1 server?"
[build-custom-image-howto]: #custom-images
[ntp]: https://en.wikipedia.org/wiki/Network_Time_Protocol


## Overview

This project uses a cheap GNSS (GPS) receiver module to achieve a clock
accuracy of well below ±1uSec. This is orders of magnitude more accurate than
syncing time using [NTP](ntp),
which might achieve about ±1mSec deviation on a LAN and perhaps ±10mSec on less
predictable connections (like most WANs).

Serving this time locally over NTP allows you to keep very accurate time on
your network, even independent of the internet.

Manage your *Raspberry Pi Time Servers* by [building custom images](#building-a-custom-image) or
from a local [Nix flake](#using-nix-flakes).


## Table of Contents

* [Features](#features)
* [Getting Started](#getting-started)
* [Installation & Configuration](#installation--configuration)
    * [Installation](#installation)
        * [Building a Custom Image](#building-a-custom-image)
    * [Configuration Using Nix Flakes](#configuration-using-nix-flakes)
        * [Example `flake.nix`](#example-flakenix)
        * [Configuring Locally](#configuring-locally)
* [Hardware Overview](#hardware-overview)
    * [Raspberry Pi Models](#raspberry-pi-models)
    * [GNSS (GPS) Receivers](#gnss-gps-receivers)
        * [Suggested Receivers](#suggested-receivers)
        * [Detailed Considerations](#detailed-considerations)
        * [Connecting the GNSS Receiver to the Raspberry Pi](#connecting-the-gnss-receiver-to-the-raspberry-pi)
    * [Real Time Clock](#real-time-clock)
        * [Connecting the RTC to the Raspberry Pi](#connecting-the-rtc-to-the-raspberry-pi)
* [How GNSS/GPS Communicates Time](#how-gnssgps-communicates-time)
    * [How GNSS Receivers Communicate Time](#how-gnss-receivers-communicate-time)
    * [PPS](#pps)
* [Known Limitations / Gotcha's](#known-limitations--gotchas)

## Features

* [x] Achieve < ±1uSec clock accuracy, compared to ±1mSec with NTP
* [x] Serve as a [stratum 1][ntporg-stratum-1] time source (even without
      internet access)
* [x] Robust and hands-off like an appliance yet customizable to fit your
      needs:
    * Sane & working defaults
    * Easy to manage & customize
    * No manual steps to "glue" things together
* [x] IPv6 Support
* [x] [NTS](https://blog.meinbergglobal.com/2021/07/14/network-time-security-nts-updated-security-for-ntp/) & [ACME](https://en.wikipedia.org/wiki/Let%27s_Encrypt#ACME_protocol)/*Let's Encrypt* Support
* [x] Nix Flake support


## Getting Started

* Attach a GNSS module like the GT-U7, Waveshare L67K or ATGM336H to your Raspberry Pi. See [GNSS Receivers](#gnss-gps-receivers) for more details.
* (Optional) Additionally attach a RTC. See [Real Time Clocks](#real-time-clock) for more details.
* Run `nix build github:koenw/stratum`
  to build the SD image or [build your own custom image](#building-a-custom-image)
* Write the image to an SD card
* Boot your Raspberry Pi from the SD card
* Permit some time for the receiver to get a fix
* Congratulations! Circumstances permitting, you now have a stratum 1 time server :)
* (When using the pre-build image) login on the console using the *stratum* username
* Continue your journey by [building pre-configured images](#building-a-custom-image), [Managing your system using Nix Flakes](#configuration-using-nix-flakes) or perusing the [options reference](./docs/options.md)


## Installation & Configuration

Configuration of the system and the SD image is done using [Nix
flakes](https://nixos.wiki/wiki/Flakes).

Just include `stratum.nixosModules.stratum` module which gives you access to
all the magic. See the [options reference](./docs/options.md) for a detailed
overview of the (stratum specific) configuration options, and the [example
`flake.nix`](./flake.nix.example) for an example.


### Installation

The recommended way to install a new *Raspberry Pi Time Server* is to bootstrap
the system by building a custom image that will have your network and users
pre-configured. After the initial boot you'll able to manage your system from a
`flake.nix` as usual.

See the [options reference](./docs/options.md) for an overview of available
options.

Alternatively, you can use the standard SD image, build with `nix build
github:koenw/stratum`, but you'll have to login using the console instead of
ssh (The user *stratum* has an empty password).


#### Building a Custom Image

The build a custom image from a `flake.nix`, simply include the
`stratum.nixosModules.sdImage` module in the *modules* section of your
*nixosSystem*. Here is an example of a `flake.nix` that includes some network
and user configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    stratum.url = "github:koenw/stratum";
  };

  outputs = { self, nixpkgs, stratum }@inputs: {
    nixosConfigurations."pitime" = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        stratum.nixosModules.sdImage
        stratum.nixosModules.stratum
        ({config, pkgs, lib, ...}:
        {
          networking = {
            hostName = "pitime";
            useDHCP = true;
            interfaces.end0 = {
              ipv6.addresses = [
                { address = "2001:db8:babe:babe::1234";
                  prefixLength = 64; }
              ];
            };
            defaultGateway6 = {
              address = "fe80::1";
              interface = "end0";
            };
          };

          # Don't forget to create a user for yourself before re-configuring,
          # or you might lock yourself out!
          # users.groups.stratum = {};
          # users.users.stratum = {
          #   isNormalUser = true;
          #   extraGroups = [ "wheel" ];
          #   group = "stratum";
          #   openssh.authorizedKeys.keys = [
          #     "ssh-ed25519 AAAAXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX stratum@purple"
          #   ];
          #   initialHashedPassword = "";
          # };

          # Set if you want to use ACME/Let's Encrypt for NTS certificates
          # security.acme.acceptTerms = true;
          # security.acme.defaults.email = "hello@example.com";

          stratum = {
            enable = true;
            ntp.allowedIPv6Ranges = [
              { address = "fe80::"; prefixLength = 10; }
              { address = "2001:db8:babe:babe::"; prefixLength = 64; }
            ];
            # Using ACME by default, see above to accept ToS & set email
            # ntp.nts.enable = true;
            # or bring your own certificates
            # ntp.nts.certificate = "/etc/bladiebla";
            # ntp.nts.key = "/etc/bladiebla";
          };
        })
      ];
    };
  };
}
```

To build the SD image for the *pitime* system in the above `flake.nix`, run
`nix build '.#nixosConfigurations.pitime.config.system.build.sdImage'`.


### Configuration Using Nix Flakes

After bootstrapping your Raspberry Pi using the initial SD image you can make
further changes by simply deploying from the same `flake.nix` you build the SD
image with:

`nixos-rebuild switch --target-host 2001:db8:babe:babe::1234 --use-remote-sudo --flake '.#pitime'`

Now that you have a running system the `stratum.nixosModules.sdImage` module is
no longer needed and can be removed from your configuration, e.g. to get rid of
the initial *stratum* local user.

See the [options reference](./docs/options.md) for an overview of available
options.


#### Example `flake.nix`

```nix
{
  description = "Example Raspberry Pi GNSS/GPS time server using stratum";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    stratum.url = "github:koenw/stratum";
  };

  outputs = { self, nixpkgs, stratum }@inputs: {
    nixosConfigurations."stratum" = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        # Uncomment to be able to build an SD image using
        # `nix build '.#nixosConfigurations."stratum".config.system.build.sdImage'`
        # stratum.nixosModules.sdImage
        stratum.nixosModules.stratum
        ({config, pkgs, lib, ...}:
        {
          networking.hostName = "stratum";

          # Don't forget to create a user for yourself before re-configuring,
          # or you might lock yourself out!
          # users.groups.stratum = {};
          # users.users.stratum = {
          #   isNormalUser = true;
          #   extraGroups = [ "wheel" ];
          #   group = "stratum";
          #   openssh.authorizedKeys.keys = [
          #     "ssh-ed25519 AAAAXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX stratum@purple"
          #   ];
          #   initialHashedPassword = "";
          # };



          # security.acme.acceptTerms = true;
          # security.acme.defaults.email = "hello@example.com";

          stratum = {
            enable = true;

            # These ranges will be allowed through the firewall and configured
            # in chrony's ACLs
            ntp.allowedIPv6Ranges = [
              { address = "fe80::"; prefixLength = 10; }
              { address = "2a02:a469:1070:babe::"; prefixLength = 64; }
            ];

            # Enable NTS with ACME (if `acme.acceptTerms` and
            # `acme.defaults.email` are set)
            ntp.nts.enable = true;

            # Configure a known offset of (about) 120ms for our serial clock
            gps.serial.offset = "0.119";

            i2c-rtc.enable = true;
          };
        })
      ];
    };
  };
}
```


#### Configuring Locally

If you'd rather make configuration changes from the Raspberry Pi itself it's
also possible to run `nixos-rebuild` locally instead:

1)  Copy the example configuration from */etc/stratum* to a local directory:

    `cp -Lr /etc/stratum ~/stratum && cd ~/stratum`

2)  Make your changes:

    `$EDITOR ./flake.nix`

3)  Make sure you've added a user for yourself, or you'll lock yourself out in
    the next step

4)  Run `sudo nixos-rebuild rebuild switch --flake '.#stratum'` to activate
    your new configuration, where *stratum* is the name of the *nixosConfiguration*
    in `flake.nix`.


## Hardware Overview

The following hardware will make for a stratum 1 time server:

* __Raspberry Pi__

    With the Raspberry Pis GPIO pins we can access both the UART and PPS output
    of the GNSS receiver.

* __GNSS (GPS) receiver__

    Since we're interested in the time it's important to pick a receiver with
    PPS or *Pulse Per Second* support.

* (Optional) __RTC__ or *Real Time Clock*

    A RTC allows the Raspberry Pi's clock to keep time across power cycles &
    reboots and decreases clock drift.


### Raspberry Pi Models

I've only tested the Raspberry Pi 4 because that's what I have, though adding
support for other models should be straight forward. Feel free to let me know
what does or doesn't work.


### GNSS (GPS) Receivers

The [GPSD website](https://gpsd.io) has a [hardware
list](https://gpsd.io/hardware.html) that you could use to compare, however, if
you're "just" looking to fix accurate time from GNSS any (cheap) GNSS receiver
with a UART (serial) interface and a separate PPS pin will do.

GNSS receivers typically speak sentences defined in NMEA-0183 or similar
protocols (over the USB, serial or bluetooth line) understood by gpsd, so
unless you happen to find some weird outlier, things should "just work".


#### Suggested Receivers

| Name            |€€€| Interfaces | PPS Pin | Channels | Frequencies | Reported accuracy |
|---              |:---:|:---             |:---:|:---:|:---:     |:---:|
| GT-U7           | € | UART, SPI, USB  | Y | 50 | L1 C/A   |N/A|
| Waveshare L76K  | € | UART            | Y | 47 | L1       | 30ns |
| ATGM336H        | € | UART, SPI, I²C  | Y | 32 | L1       | 30ns |


#### Detailed Considerations

TL;DR: Just pick one using UART (serial) protocol and a separate PPS pin.

<details>
<summary>Communication Interfaces</summary>

It's important this interface incurs as little latency as possible, because any
latency here will translate directly to an offset and any variance in latency
to skew. USB 1.x and 2.x both use a multiplexing protocol based on polling
which introduces a undesirable latency so a serial/UART connection is preferred
over those.

In addition to the serial connection, we prefer a separate PPS output that we
can directly connect to a GPIO pin of the Raspberry Pi (without any protocol
overhead).
</details>
<details>
<summary>Channels & frequencies</summary>

In order to sync their PPS signal with the atomic clocks in the satellites, the
GNSS receiver needs to get a "fix": gather it's distance and position relative to
at least 4 satellites. The more satellites the receiver can keep in view at any
time, the easier it is to find or maintain a fix.

Most receivers can only receive from at most 3 out of 4 (GPS, Galileo, GLONASS
& BeiDou) constellations at the same time, some don't support all
constellations.
</details>
<details>
<summary>Constellations</summary>

Not all receivers can receive all constellations (GPS, Galileo, GLONASS &
BeiDou) and most that can can only receive from at most 3 out of 4 at the same
time.

</details>
<details>
<summary>(Indoor) Sensitivity</summary>

Some receivers might be more or less sensitive. If you're placing your antenna
outside or near a window (as you should) this shouldn't mater too much, however
if you're looking to receive GNSS signals indoors you might need to go for a
more sensitive receiver.
</details>


#### Connecting the GNSS Receiver to the Raspberry Pi

This assumes a UART (serial) GNSS receiver, which uses 4 pins plus hopefully an
additional pin for PPS:

| Name(s)           | Description   | Raspberry Pi Pin  |
| :---              | :---           | :---               |
| Vin, VCC, Power   | DC power supply, often +5V | Pin 2 or 4 (*5V Power*) |
| GND               | DC common ground | Pin 6, 9 or 14 (*GND*) |
| TX                | *Transmitting* (NMEA) messages | Pin 10 (GPIO 15, *UART RX*) |
| RX                | *Receiving* messages   | Pin 8 (GPIO 14, *UART TX*) |
| PPS               | The [PPS](https://en.wikipedia.org/wiki/Pulse-per-second_signal) signal | Pin 12 (GPIO 18, *PCM CLK*) |


### Real Time Clock

A [RTC](https://en.wikipedia.org/wiki/Real-time_clock) or *Real Time Clock*
is an (often) crystal oscllilator, connected to some logic and a separate
battery that keeps track of the time. The Raspberry Pi 5 already comes with
a RTC built-in, for the other models you can attach a cheap RTC to the I²C
GPIO pins.

Although optional, they offer several advantages:

* The RTC will keep track of time even during reboots or power loss (without
  it, the hardware clock would reset on every power cycle).
* Faster GNSS/GPS fixes on a cold boot (depending on the receiver)
* (Supposedly) even less drift/jitter

Some often used RTCs for the Raspberry Pi are the DS3107, DS1337, and
DS3231, of which the DS3231 is supposed to be the most reliable.


#### Connecting the RTC to the Raspberry Pi

Most RTCs talk to the Raspberry Pi using I<sup>2</sup>C, which means it
should come with 4 pins:

| Name(s)   | Description   | Raspberry Pi Pin |
| :---      | :---           | :--- |
| Vin, +    | DC Power supply, often +3V but sometimes +5V, check your datasheet | GPIO 1 for 3V, GPIO 2 or 4 for 5V |
| SDA       | *Serial Data*, to send and receive data (the time information) | GPIO 3 |
| SCL       | *Serial Clock* carries the shared clock signal to coordinate the sending/receiving on the SDA line |  GPIO 5 |
| GND       | DC common ground | GPIO 6 or 9 |

Due to the way the Raspberry Pi's GPIO pins are laid out, with *3V*,
*I<sup>2</sup>C SDA*, *I<sup>2</sup>C SCL* and *GND* right next to each other
(ignoring GPIO 7), many RTC clocks (e.g. [this
one](https://www.seeedstudio.com/Pi-RTC-DS1307.html)) are designed to plug right
into the Raspberry Pi without needing any wires.


## How GNSS/GPS Communicates Time

At the core of GNSS/GPS is time keeping. The GNSS satellites contain highly
accurate atomic clocks that are kept in sync with each other.

These clocks are directly connected to a transmitting radio, which the
satellites use to regularly broadcast the precise time according to their clock
to earth.

By listening to these signals we can now know the approximate time, but because
we don't know precisely how long it took for the radio signal to get to us, we
can't know it very precisely (yet).

Together with the clock signal each satellite periodically broadcasts its
[*ephemeris*](https://en.wikipedia.org/wiki/Ephemeris) data (a bit like a bus
schedule for satellites), which we can use to calculate the precise location of
the satellite at any given point in time. This means we now know where exactly
the satellite was when it send the time signal.

By comparing the timing signals we receive from multiple satellites and taking
into account their locations relative to each other (and the speed of light),
we can now infer how long it took for the signals to reach us and consequently
our precise time & location.

In addition to the basic algorithm described above, most GNSS receivers use
more sources of information, such as the perceived shift in frequency in a
satellite signal ([Dopller
shift](https://www.e-education.psu.edu/geog862/node/1786)) and what satellites
share about how they perceive other satellites.


### How GNSS Receivers Communicate Time

Most GNSS receivers use a variant of the
[NMEA](https://en.wikipedia.org/wiki/NMEA_0183) protocol to communicate over
UART (serial). These protocols define a set of
[sentences](https://www.rfwireless-world.com/Terminology/GPS-sentences-or-NMEA-sentences.html)
a *talker* (the GNSS receiver) can speak to *listeners* (the Raspberry Pi).

This means that if all is well, you should be able to follow these messages
arriving at our UART/serial RX port by reading from the serial device (if no
other program like [`gpsd`](https://gpsd.io/) is already consuming them):

```sh
root@pitime:~/ > tail /dev/ttyS1 -f
$GPGGA,092750.000,5321.6802,N,00630.3372,W,1,8,1.03,61.7,M,55.2,M,,*76
$GPGSA,A,3,10,07,05,02,29,04,08,13,,,,,1.72,1.03,1.38*0A
$GPGSV,3,1,11,10,63,137,17,07,61,098,15,05,59,290,20,08,54,157,30*70
$GPGSV,3,2,11,02,39,223,19,13,28,070,17,26,23,252,,04,14,186,14*79
$GPGSV,3,3,11,29,09,301,24,16,09,020,,36,,,*76
$GPRMC,092750.000,A,5321.6802,N,00630.3372,W,0.02,31.66,280511,,,A*43
$GPGGA,092751.000,5321.6802,N,00630.3371,W,1,8,1.03,61.7,M,55.3,M,,*75
$GPGSA,A,3,10,07,05,02,29,04,08,13,,,,,1.72,1.03,1.38*0A
$GPGSV,3,1,11,10,63,137,17,07,61,098,15,05,59,290,20,08,54,157,30*70
$GPGSV,3,2,11,02,39,223,16,13,28,070,17,26,23,252,,04,14,186,15*77
$GPGSV,3,3,11,29,09,301,24,16,09,020,,36,,,*76
$GPRMC,092751.000,A,5321.6802,N,00630.3371,W,0.06,31.66,280511,,,A*45
```

The NMEA sentences consists of comma-separated fields, the first of which
denotes the sentence type (e.g. `$GPGGA` or `$GPRMC`) and dictates how the
other fields should be interpreted.  Some of these sentences, like the final
`$GPRMC` sentence in the above output, communicate the time.  Here the second
field, `092751.000`, indicates this message was send at 09 hours, 27 minutes
and 51.000 seconds UTC.

However because it once again takes time to send/receive the clock message
we're again limited in the precision with which we can know the time. For
example, if our GNSS receiver and Raspberry Pi would communicate using a 9600
baud-rate, receiving the first 16 bytes of the `$GPRMC` sentence alone will
take $16 / 9600 = 0.001666$ seconds or 1.7 ms.

For this reason, some GNSS receivers offer an additional output useful for
those interested in keeping accurate time: The *PPS* or *Pulse Per Second*
output.


#### PPS

The [PPS](https://en.wikipedia.org/wiki/Pulse-per-second_signal) or *Pulse Per
Second* is a separate output signal on a dedicated pin characterized by a very
abrupt rising or falling edge that repeats once per second. This is used by the
GNSS receiver to accurately communicate the edge of each second and if we
combine this with the timing information from the NMEA sentences we can
(almost<sup>[1](#known-limitations--gotchas)</sup>) rely on GNSS alone to bootstrap our sense-of-time.


## Known Limitations / Gotcha's

* __Fresh images require up-to-date (U-boot) firmware to boot__ and might be unable
  to boot on devices with older firmware. If that happens, update the firmware
  from an existing (already installed & updated) image/sdcard (e.g. from an
  existing *Raspberry Pi Time Server* or even Raspbian):

      ```sh
      nix-shell -p raspberrypi-eeprom
      sudo mount /dev/disk/by-label/FIRMWARE /mnt
      sudo BOOTFS=/mnt FIRMWARE_RELEASE_STATUS=stable rpi-eeprom-update -d -a
      ```

* __The bootloader prompt has been disabled__ to make unattended boots
  possible. Because GNSS receiver modules send their data on the serial console
  even before the OS is properly booted, the bootloader will receive data on
  the serial port and will interpret this as a keyboard interrupt, pausing the
  boot process.
* __The antenna will need a clear view of the sky.__ Some sensitive GNSS
  receivers/antennas are designed to function indoors, but in general you will
  need a *line of sight* to the satellites.
* __It might take >30 minutes for your receiver to__ [__establish its first
  fix__](https://en.wikipedia.org/wiki/Time_to_first_fix) depending on
  circumstances.
* __The onboard Bluetooth module has been disabled__ because it shares a
  communication bus with the GPIO pins we use to communicate with the GNSS
  receiver which can lead to interference in some cases.
* __It's impossible to get an automatic fix outside the assumed__ [__GPS
  epoch__](https://en.wikipedia.org/wiki/GPS_week_number_rollover)__.__ The
  time signal used to calibrate the
  [PPS](https://en.wikipedia.org/wiki/Pulse-per-second_signal) is transmitted
  as a combination of of a 10bit weeknumber (starting at January 6th 1980) and
  the number of seconds into that week. This means every 2<sup>10</sup> weeks
  or about every 19.67 years a rollover occurs where the weeknumber rolls back
  to 0. At the time of writing we're in the 3rd epoch and the next rollover
  will occur in November 2038.

  Without outside help (e.g. manually or by the NTP protocol) many receivers
  default to a hardcoded epoch, which without firmware updates might be out-of-date.

  Newer protocols have longer epochs but are not yet widely supported.

* __Initial system clock sync can take a long time.__ Even after the GNSS
  receiver has found a fix and chrony is synced to the GNSS clock, by default
  chrony only updates the system clock in small steps to not upset software
  with big time jumps. Use `chronyc makestep` to set the system clock right
  once. A [RTC](#real-time-clock) can prevent this issue recurring by keeping the
  system clock reasonably close.


## Further Reading

* [GPSD Introduction to Time Service](https://gpsd.io/time-service-intro.html)
* [GPSD Time Service HOWTO](https://gpsd.io/gpsd-time-service-howto.html)
* [Building a Raspberry Pi NTP Server](https://www.satsignal.eu/ntp/Raspberry-Pi-NTP.html)
* [domschl/RaspberryNtpServer](https://github.com/domschl/RaspberryNtpServer)
