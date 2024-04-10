# Stratum options


## stratum\.enable

Enable the Stratum (1) GNSS time server\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)



## stratum\.gps\.gpsd_watchdog\.enable



In some cases a GNSS device can be deactived only to return a few
seconds later (with some modules more than others)\. However, by this
time gpsd has often already removed the device and because gpsd drops
root priviliges after initialization it is unable to re-initialize
the device\.

The proper solution would be to fix the issue of why your GPS
module resets (faulty cabling, faulty module, another device
using the same GPIO pins, etc)\.

See  [this gpsd issue](https://gitlab\.com/gpsd/gpsd/-/issues/211) for
more details\.

This option will enable a watchdog that will monitor chrony \& gpsd
and restart gpsd when it detects that gpsd hasn’t been forwarding the
NMEA and PPS signals for a while\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)



## stratum\.gps\.ignore_boot_interrupts



Most GNSS devices will transmit data on the serial port before being
talked to, making u-boot and the bootloader think the user pressed a
keyboard button to interrupt autoboot\.

Because we’d like our device to boot without interaction we force the
bootloader to not prompt the user\. Because we override a generated
config file, we take care to “fix” this everytime this file gets
overwritten\.

Ideally we would fix this properly, so we can rely on the bootloader
for fault-recovery\.



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)



## stratum\.gps\.pps\.lock



The NTP Reference ID (refid) of another reference clock to lock the
PPS clock to\.

Because the PPS device only tells us the (quite exact) edge of a
second but not what second that is, we need another clock source to
be able to actually tell the time of day\.

This option allows us to “lock” the PPS signal to another refclock,
adding the precision of the PPS signal to the more complete but
(presumably) less accurate other refclock\.



*Type:*
string



*Default:*
` "NMEA" `

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)



## stratum\.gps\.pps\.path



Path to the GNSS PPS device

Note that some GNSS receivers will only initialize the PPS device
after being talked to by [gpsd](https://gpsd\.io/)\.



*Type:*
string



*Default:*
` "/dev/pps0" `

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)



## stratum\.gps\.pps\.refid



The NTP Reference ID (refid) for the PPS clock\.

In the NTP response message this is a field that in the case of a
stratum 1 server (like us) indicates what their stratum 0 clock is\.
There is an authoritative list of Reference Identifiers maintained by
IANA, see
[here](https://www\.meinbergglobal\.com/english/info/ntp-refid\.htm) for
an overview\.

If you’ve configured your GNSS receiver to only use a particular
constellation, other values of interest might be *GOES*, *GPS* or
*GAL*\. The default value of *PPS* indicates a generic
pulse-per-second refclock\.



*Type:*
unspecified value



*Default:*
` "PPS" `

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)



## stratum\.gps\.serial\.offset



The known constant offset of this device (not including the PPS signal)

After monitoring your situation for a bit you’ll probably notice the
serial-connected device as a somewhat-constant offset from the PPS
signal, which you can configure here for extra clean output\.



*Type:*
null or string



*Default:*
` null `



*Example:*
` "0.120" `

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)



## stratum\.gps\.serial\.path



Path to the GNSS/GPS UART/serial device



*Type:*
string



*Default:*
` "/dev/ttyS1" `

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)



## stratum\.gps\.serial\.refid



The NTP Reference ID (refid) for this device

In the NTP message the server returns to the client, this is a field
that can be used by stratum 1 servers (like us) to indicate what
their stratum 0 clock is\. There is an authoritative list of Reference
Identifiers maintained by IANA, see
[here](https://www\.meinbergglobal\.com/english/info/ntp-refid\.htm) for
an overview\.

In addition to enabling clients to tell the source of their time, the
refid can also be used to lock a PPS reference clock to another
clock\.

This is the refid for the UART device which we will actually not
broadcast to clients, so it doesn’t matter that much what you set
this to\. Do keep in mind restrictions apply (e\.g\. only ascii, max 4
chars)\.



*Type:*
string



*Default:*
` "NMEA" `

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)



## stratum\.i2c-rtc\.enable



Whether to enable I2C Real Time Clock support\.



*Type:*
boolean



*Default:*
` false `



*Example:*
` true `

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)



## stratum\.i2c-rtc\.address



The I²C address of the RTC

Detect with ` i2cdetect <bus> `



*Type:*
string



*Default:*
` "0x68" `

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)



## stratum\.i2c-rtc\.bus



The I²C bus the RTC is connected to\.



*Type:*
positive integer, meaning >0



*Default:*
` 3 `

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)



## stratum\.i2c-rtc\.model



RTC model

This will be passed to the kernel driver\. If your model isn’t directly
known by the kernel, you might get lucky using the “ds1307” model string
as fallback\.



*Type:*
string



*Default:*
` "ds3231" `



*Example:*
` "ds1307" `

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)



## stratum\.ntp\.enable



Enable the (chrony) NTP Server



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)



## stratum\.ntp\.allowedIPv6Ranges



The IPv6 Ranges that will be allowed to query our NTP server\.

This will open the firewall and configure the ACL’s in chrony\.



*Type:*
unspecified value



*Default:*

```
[
  {
    address = "fe80::";
    prefixLength = 10;
  }
]
```



*Example:*

```
[
  {
    address = "fe80::";
    prefixLength = 10;
  }
  {
    address = "2001:db8::";
    prefixLength = 32;
  }
]
```

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)



## stratum\.ntp\.servers



List of NTP servers to use for monitoring\.

These servers are strictly optional and not used by chrony to adjust
the clock\. Instead they can be monitored (e\.g\. with ` chronyc sources `)
to get a sense of our time compared to the community\.



*Type:*
unspecified value



*Default:*

```
[
  "0.nixos.pool.ntp.org"
  "1.nixos.pool.ntp.org"
  "2.nixos.pool.ntp.org"
  "3.nixos.pool.ntp.org"
  "4.nixos.pool.ntp.org"
]
```

*Declared by:*
 - [/nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options\.nix](file:///nix/store/xsgfkwpgai1yx1r23mwpi4dpyxbz1y8g-source/modules/options.nix)


