[
  (_final: prev: {
    # pytest 9.1 treats a trailing comma in `parametrize` argnames as
    # tuple-style, so pipx 1.14.0's tests/test_inject.py fails at collection.
    # nixpkgs already deselects every test in that file via its "inject"
    # disabledTests entry (they need network), but `-k` filters after
    # collection, so only a pre-collection ignore avoids the error. Fixed
    # upstream after 1.14.0; drop this once nixpkgs ships that release.
    pipx = prev.pipx.overridePythonAttrs (old: {
      disabledTestPaths = (old.disabledTestPaths or [ ]) ++ [ "tests/test_inject.py" ];
    });
  })
]
