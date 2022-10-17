#!/bin/bash
rm template/release.lua
read -p "enter release version: " version
sed -e "s/branch = 'unknown'/branch = '$(git rev-parse --abbrev-ref HEAD)'/" -e "s/commit = 'unknown'/commit = '$(git rev-parse --short HEAD)'/" -e "s/version = 'unknown'/version = '$version'/" template/release_blank.lua > template/release.lua