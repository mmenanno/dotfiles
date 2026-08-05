{ inputs, lib, isWorkMachine ? false, ... }:

let
  ralphClaudeCode = inputs.ralph-claude-code;
  ghStack = inputs.gh-stack;

  ralphSkills = {
    ".claude/skills/brief".source = "${ralphClaudeCode}/skill/brief";
  };

  ralphScript = {
    ".local/bin/ralph" = {
      source = "${ralphClaudeCode}/ralph";
      executable = true;
    };
  };

  ghStackSkill = {
    ".claude/skills/gh-stack".source = "${ghStack}/skills/gh-stack";
  };

in {
  home.file = ghStackSkill // lib.optionalAttrs (!isWorkMachine) (ralphSkills // ralphScript);
}
