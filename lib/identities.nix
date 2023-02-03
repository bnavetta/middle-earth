with builtins; let
  notComment = s: stringLength s == 0 || (substring 0 1 s) != "#";
  ageRecipients = path: let
    contents = readFile path;
    lines = filter isString (split "\n" contents);
  in
    filter notComment lines;
in rec {
  # Attrset mapping each host to its age identities
  hosts = fromJSON (readFile ../secrets/identities.json);

  # List of all host-level age identities
  allHosts = foldl' (a: b: a ++ b) [] (attrValues hosts);

  # SSH and age identities for users
  users = {
    ben = {
      ssh = [
        # Original
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDu/wJ+D0V8NKGzkcFYsdDhNJb2xlOm9SZLUPLbYY6FFTk19YNuCSgiXl5jDKqPsFQ/ARgUK6BuHTjfpYxaoG21aNf9nIp/gKO4fGxbEJnUWDXkXr1eKT3Aqb/9rtw0zTTX6YFUMCC/EQsfsDsk5+IrIaWK9H5D0ycH6bhaPtkkGPxkKHBrfxQmaJV2vebS3Lv7VvspqUNFKHBi/u/h6kn+91oIe/akwlYNdFTa4Ah91PAhfYk4fVxGUgFIci5o3cSDC2jMo7ZSeqM49Z6pLNEJAB18QNsEGGp+Wkz5gvVzcUqgivsk6CZDMvWtT9s9YcvNZ7rQEkLtU+L1ueiNjyWJE4PgZ97hhuBJA2UmyuM+urmW8Z8dF8nejXPvkFRslueZnpJLLGM55J+qy/gs5WLkzsNaZCD9vi06M7w+ms0SQO0Bv6F3JNNxuPmfuERDXg9oqzjWmuE836NV8bSY926sPKliNTAfaR6DACHCQaQZolr5My9z5UDYB9LJTtQgMvrVcMQHPrGM1sAdwEgHk/GT9xYymywAUwK/nv+034zlSgMGVEQO92NnFRQlr1kvtIKpRAUVWAolIZvveKCC8gc5PbAmi7I8Oyx08YjwYUOB64sJIlx95jeHmdz9Yn1zhOC4BZEKg3fHv5ojaygY0kvBMIW0Lh1sSoP4+aOkqXYL5Q== # yubikey"
        # Keychain
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBALBuAN9GCKc3BBc/gIN7LSkHQau0LOV3glwI4UCuaJ3Oreh3M1gMjPKZ2yOnoWJekilT4GcTCMYbKNh0Mu8xWw="
        # Backup
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBAsujdektEsHX/OtFwoE6VVKTafP+q5Azh1O5MVvgPThkUvPKdv0eE4FC3BJCssNsWUHvlCHY3DqzGvKnSLcXnk="
      ];
      age = ageRecipients ../users/users/ben/age-recipients.txt;
    };
  };
  admins = users.ben.age;
}
