#!/bin/bash
zip -9 -r package-template.zip --exclude="*.git/*" --exclude="*template/.git*" --exclude="*.gitignore_local*" --exclude="*.gitmodules*" --exclude="*.typings*" --exclude="*template/docs*" --exclude="*README.md" --exclude="*.sm.auto*" --exclude="*.sm.old*" --exclude="*distribute-template.sh*" .