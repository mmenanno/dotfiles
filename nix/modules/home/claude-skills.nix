{ inputs, ... }:

let
  ralphClaudeCode = inputs.ralph-claude-code;

  ralphSkills = {
    ".claude/skills/brief".source = "${ralphClaudeCode}/skill/brief";
  };

  ralphScript = {
    ".local/bin/ralph" = {
      source = "${ralphClaudeCode}/ralph";
      executable = true;
    };
  };

in {
  home.file = ralphSkills // ralphScript;
}
