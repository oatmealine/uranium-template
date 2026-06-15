#!/usr/bin/env bash
read -rp "enter release version: " version
sed -i \
  -e "s/branch = '.+'/branch = '$(git rev-parse --abbrev-ref HEAD)'/" \
  -e "s/commit = '.+'/commit = '$(git rev-parse --short HEAD)'/" \
  -e "s/version = '.+'/version = '$version'/" \
  template/uranium/internal/release.lua