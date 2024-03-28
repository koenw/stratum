{
  config = {
    services.openssh = {
      enable = true;
      settings = {
        Ciphers = [
          "chacha20-poly1305@openssh.com"
        ];
        KexAlgorithms = [
          "sntrup761x25519-sha512@openssh.com"
        ];
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
        ];
        UseDns = false;
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
      extraConfig = ''
        AuthenticationMethods publickey
      '';
    };
  };
}
