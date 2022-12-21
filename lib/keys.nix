{
  users = {
    ben = {
      # RSA SSH keys stored in a YubiKey's PIV applet can't be used with age-plugin-yubikey: https://github.com/str4d/age-plugin-yubikey/issues/62
      # In addition, age doesn't support ssh-agent, so it can't access keys that way (https://github.com/ryantm/agenix#notices)
      ssh = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDu/wJ+D0V8NKGzkcFYsdDhNJb2xlOm9SZLUPLbYY6FFTk19YNuCSgiXl5jDKqPsFQ/ARgUK6BuHTjfpYxaoG21aNf9nIp/gKO4fGxbEJnUWDXkXr1eKT3Aqb/9rtw0zTTX6YFUMCC/EQsfsDsk5+IrIaWK9H5D0ycH6bhaPtkkGPxkKHBrfxQmaJV2vebS3Lv7VvspqUNFKHBi/u/h6kn+91oIe/akwlYNdFTa4Ah91PAhfYk4fVxGUgFIci5o3cSDC2jMo7ZSeqM49Z6pLNEJAB18QNsEGGp+Wkz5gvVzcUqgivsk6CZDMvWtT9s9YcvNZ7rQEkLtU+L1ueiNjyWJE4PgZ97hhuBJA2UmyuM+urmW8Z8dF8nejXPvkFRslueZnpJLLGM55J+qy/gs5WLkzsNaZCD9vi06M7w+ms0SQO0Bv6F3JNNxuPmfuERDXg9oqzjWmuE836NV8bSY926sPKliNTAfaR6DACHCQaQZolr5My9z5UDYB9LJTtQgMvrVcMQHPrGM1sAdwEgHk/GT9xYymywAUwK/nv+034zlSgMGVEQO92NnFRQlr1kvtIKpRAUVWAolIZvveKCC8gc5PbAmi7I8Oyx08YjwYUOB64sJIlx95jeHmdz9Yn1zhOC4BZEKg3fHv5ojaygY0kvBMIW0Lh1sSoP4+aOkqXYL5Q== # yubikey";
      age = "age1yubikey1q0janequt0yrz9jdzy70en89gw626hfh3amgm404g55q5agev47qvrutcdh";
    };
  };

  hosts = builtins.mapAttrs (name: _: builtins.readFile ../hosts/${name}/ssh_pubkey) (builtins.readDir ../hosts);
}
