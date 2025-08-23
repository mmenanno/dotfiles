{ ... }:
{
  programs.gh = {
    enable = true;
    settings = {
      editor = "cursor";
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };
}
