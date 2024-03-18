module Test.Main where

import Prelude

import Data.Maybe (Maybe(..))
import Data.String as String
import Effect (Effect)
import Sunde as S
import Test.Unit (suite, test)
import Test.Unit.Assert as Assert
import Test.Unit.Main (runTest)

main :: Effect Unit
main = runTest do
  suite "Sunde" do
    test "works with ls" do
      result <- S.spawn { cmd: "ls", args: [], stdin: Nothing } identity
      Assert.equal (show result.exit) "Normally 0"
      Assert.assert "stdout is not empty" $ String.length result.stdout > 0
      Assert.assert "stderr is empty" $ String.length result.stderr == 0

    test "works with cat" do
      result <- S.spawn { cmd: "cat", args: [], stdin: Just "hello" } identity
      Assert.equal (show result.exit) "Normally 0"
      Assert.assert "stdout is hello" $ result.stdout == "hello"
      Assert.assert "stderr is empty" $ String.length result.stderr == 0

    test "breaks with ls with garbage options" do
      result <- S.spawn { cmd: "ls", args: [ "-askdfjlaskdfjalsdf" ], stdin: Nothing } identity
      Assert.assert "stdout is empty" $ String.length result.stdout == 0
      Assert.assert "stderr is not empty" $ String.length result.stderr > 0
      Assert.equal (show result.exit) "Normally 2"
