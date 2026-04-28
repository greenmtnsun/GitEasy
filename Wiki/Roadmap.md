# Roadmap

## Next

- Add clean-but-ahead push behavior to Save-Work.
- Move native Git execution into Private\Invoke-GEGitCommand.ps1.
- Add Pester tests for Save-Work and Assert-GESafeSave.

## Test Coverage Needed

- CRLF warnings are not conflicts.
- Real conflicts block Save-Work.
- Save-Work -NoPush works.
- Native Git stderr does not falsely fail Save-Work.
- Commit messages are written without BOM.
- Clean-but-ahead branches are pushed.
