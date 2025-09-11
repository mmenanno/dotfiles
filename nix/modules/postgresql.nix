{ pkgs, username, ... }:

{
  # Install PostgreSQL server and client tools
  environment.systemPackages = with pkgs; [ postgresql ];

  # Launch PostgreSQL as a LaunchDaemon (nix-darwin)
  services.postgresql = {
    enable = true;
    # Use a dataDir in /var/lib managed by launchd; created on first start
    dataDir = "/var/lib/postgresql";
    package = pkgs.postgresql;
    # Create a default DB matching the primary user
    initialScript = pkgs.writeText "pgsql-init.sql" ''
      DO $$ BEGIN
        CREATE ROLE ${username} LOGIN SUPERUSER;
      EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE 'role ${username} already exists';
      END $$;
      CREATE DATABASE ${username} OWNER ${username};
    '';
    settings = {
      listen_addresses = "localhost";
      shared_buffers = "128MB";
      max_connections = 100;
      log_min_duration_statement = 1000;
    };
    authentication = ''
      # type  database  user         address        method
      local   all       all                        trust
      host    all       all         127.0.0.1/32   trust
      host    all       all         ::1/128        trust
    '';
  };
}


