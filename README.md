# PureScript Sunde

[![Build Status](https://travis-ci.org/justinwoo/purescript-sunde.svg?branch=master)](https://travis-ci.org/justinwoo/purescript-sunde)

Just provides an easy function for spawning a node process and getting stdout/stderr/exit as an Aff.

![](https://i.imgur.com/ilxPhqD.png)

If you disagree with anything in this library, send a PR or make your own library.

## Example

```hs
import Node.ChildProcess as CP
import Sunde as S

main = runTest do
  suite "Sunde" do
    test "works with ls" do
      result <- S.spawn { cmd: "ls", args: [], stdin: Nothing } CP.defaultSpawnOptions
      Assert.equal (show result.exit) "Normally 0"
      Assert.assert "stdout is not empty" $ String.length result.stdout > 0
      Assert.assert "stderr is empty" $ String.length result.stderr == 0
```
