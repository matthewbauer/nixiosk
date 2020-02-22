{ pkgs, lib, ... }:
{
  imports = [
    ./cage.nix
  ];

  time.timeZone = "America/New_York";

  services.cage = {
    enable = true;
    user = "kiosk";
    program = "${pkgs.gnome3.gnome-chess}/bin/gnome-chess";
  };

  documentation.enable = false;
  services.nixosManual.showManual = false;
  services.openssh.enable = true;

  users.users.kiosk = {
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC97Tk7707CyQ3urunhiW/HoqE5679dcK43MfZVtmcRsgLCi7e16wIdr9Zg8SWSgMg2FbazhvmydwzOg8Ovr3tk6gJP+/dWqjtXgz6i+W2n2nlxw/YGSjRniUU/Kvt8WBR99z8aXD5wUwGbqRsHzNrKm6OTIXMCKQJVP36E5XEzMoRsqhIG/fZaR0Lz5nXDq1d5XlxHk8ZAV7SCf8Mf2zV5ZOv1e8rxnZXdxjKsvlOsVXTmPLg8xC7xdrrbmcIlON+YlX50b7/Xm4+jnqu9moFa8c3FJTBrY3NiYa/G4DhXKaNC4hhweMWiQIGY0lgPDf3THp/dDQITkOeUf8nSzJDn mbauer@gmail.com"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKSOjquyB+H5MlCpzG92v9RXOStLs2rc4XE09AXpj1nkAKySWjt209oY5j0Q7XUjxVEHRDRIRTB12hwLXw2QMuNMVUEpGZ9icLMo1Rj2HQUmPS6FNI3AleEX/zXmAHcmB1OeUh3aKfrAEOml/DqGTUoyL8iRNV5P8jKheFzncnVMSCLVPxs6zh0Do/a7Nu3vLay1szap94QhRBmtQoBhgXyF3wjbvffLboDkwsDs5GHDEt3nzMxArytomqleK/65YgU1M/jwEL6bqCb96BfpkEbP+lVr9ezJsOVTgWDRDCWFfN0pUsYwsLlgz2dY6c+o1Q/25x26Mf7iyrlimtVMSt"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC050iPG8ckY/dj2O3ol20G2lTdr7ERFz4LD3R4yqoT5W0THjNFdCqavvduCIAtF1Xx/OmTISblnGKf10rYLNzDdyMMFy7tUSiC7/T37EW0s+EFGhS9yOcjCVvHYwgnGZCF4ec33toE8Htq2UKBVgtE0PMwPAyCGYhFxFLYN8J8/xnMNGqNE6iTGbK5qb4yg3rwyrKMXLNGVNsPVcMfdyk3xqUilDp4U7HHQpqX0wKrUvrBZ87LnO9z3X/QIRVQhS5GqnIjRYe4L9yxZtTjW5HdwIq1jcvZc/1Uu7bkMh3gkCwbrpmudSGpdUlyEreaHOJf3XH4psr6IMGVJvxnGiV9 mbauer@dellbook"
    ];
    isNormalUser = true;
    useDefaultShell = true;
    extraGroups = [ "wheel" ];
  };

  networking.hostName = "kiosk";

}
