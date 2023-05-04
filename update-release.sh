#!/bin/bash
rm template/uranium/release.lua
read -p "enter release version: " version
sed -e "s/branch = 'unknown'/branch = '$(git rev-parse --abbrev-ref HEAD)'/" -e "s/commit = 'unknown'/commit = '$(git rev-parse --short HEAD)'/" -e "s/version = 'unknown'/version = '$version'/" template/uranium/release_blank.lua > template/uranium/release.lua