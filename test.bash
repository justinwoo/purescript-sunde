#! /usr/bin/env nix-shell
#! nix-shell ci.nix -i bash

npm i
bower install

pulp test
