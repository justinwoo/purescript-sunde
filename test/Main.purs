module Test.Main where

import Prelude

import Data.String as String
import Node.ChildProcess as CP
import Sunde as S
import Test.Unit (suite, test)
import Test.Unit.Assert as Assert
import Test.Unit.Main (runTest)

main :: _
main = runTest do
  suite "Sunde" do
    test "works with ls" do
      result <- S.spawn "ls" [] CP.defaultSpawnOptions
      Assert.equal (show result.exit) "Normally 0"
      Assert.assert "stdout is not empty" $ String.length result.stdout > 0
      Assert.assert "stderr is empty" $ String.length result.stderr == 0

    test "breaks with ls with garbage options" do
      result <- S.spawn "ls" ["-askdfjlaskdfjalsdf"] CP.defaultSpawnOptions
      Assert.assert "stdout is empty" $ String.length result.stdout == 0
      Assert.assert "stderr is not empty" $ String.length result.stderr > 0
      Assert.equal (show result.exit) "Normally 2"
