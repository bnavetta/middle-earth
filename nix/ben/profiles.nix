{
  inputs,
  cell,
}: let
  inherit (inputs.cells) base;
  inherit (cell) homeProfiles;

  sshKeys = [
    # Original
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDu/wJ+D0V8NKGzkcFYsdDhNJb2xlOm9SZLUPLbYY6FFTk19YNuCSgiXl5jDKqPsFQ/ARgUK6BuHTjfpYxaoG21aNf9nIp/gKO4fGxbEJnUWDXkXr1eKT3Aqb/9rtw0zTTX6YFUMCC/EQsfsDsk5+IrIaWK9H5D0ycH6bhaPtkkGPxkKHBrfxQmaJV2vebS3Lv7VvspqUNFKHBi/u/h6kn+91oIe/akwlYNdFTa4Ah91PAhfYk4fVxGUgFIci5o3cSDC2jMo7ZSeqM49Z6pLNEJAB18QNsEGGp+Wkz5gvVzcUqgivsk6CZDMvWtT9s9YcvNZ7rQEkLtU+L1ueiNjyWJE4PgZ97hhuBJA2UmyuM+urmW8Z8dF8nejXPvkFRslueZnpJLLGM55J+qy/gs5WLkzsNaZCD9vi06M7w+ms0SQO0Bv6F3JNNxuPmfuERDXg9oqzjWmuE836NV8bSY926sPKliNTAfaR6DACHCQaQZolr5My9z5UDYB9LJTtQgMvrVcMQHPrGM1sAdwEgHk/GT9xYymywAUwK/nv+034zlSgMGVEQO92NnFRQlr1kvtIKpRAUVWAolIZvveKCC8gc5PbAmi7I8Oyx08YjwYUOB64sJIlx95jeHmdz9Yn1zhOC4BZEKg3fHv5ojaygY0kvBMIW0Lh1sSoP4+aOkqXYL5Q== # yubikey"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOJMAHqzhBlc+xoolHGv+tBleAVfoT1znAfC6/2Ogpax6+OPnWBECR8+gksRFIToLV9nHTtx5Ps6z6L9ywZsJOK9WBRx7rRJCoDZS/3VsJ7o5lzNXnifNzeKIx/ojolmlZ8fWACG4FXl0efQMty0q2bl83s8VMyXX7w876guu+EeCOMyZoQT46sm7gYAuL33eoSxu7ck4aEHu+VNQWfEjfxSCZvqU+JZBpGGOHAif1PvSavO6r0bsfI/u5MlqRgobwQZyU1cWPSSZ//wFnYj9e2eQPN2EK/+pMOOD+0HtIvdaWC0UhJnKPEHyrw5CF+QVI5UyDxNlyHfmd1Sbo7SKx YubiKey #11482632 PIV Slot 9a"
  ];
in {
  nixos = base.lib.mkModule "Ben's user configuration for NixOS" ({...}: {
    # Also set SSH keys for root?
    users.users.sysadmin.openssh.authorizedKeys.keys = sshKeys;

    users.users.ben = {
      # TODO: password file
      password = "ben";
      description = "Ben";
      isNormalUser = true;
      createHome = true;
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = sshKeys;
    };

    home-manager.users.ben = {...}: {
      imports = [
        homeProfiles.common
        homeProfiles.desktop
        base.homeProfiles.state
      ];
    };
  });
}
