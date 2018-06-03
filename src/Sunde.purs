module Sunde where

import Prelude

import Data.Either (Either(..))
import Data.Posix.Signal (Signal(..))
import Effect.Aff (Aff, effectCanceler, makeAff)
import Effect.Ref (modify_, new, read)
import Node.ChildProcess as CP
import Node.Encoding (Encoding(..))
import Node.Stream (onDataString)

spawn
  :: String
  -> Array String
  -> CP.SpawnOptions
  -> Aff
      { stdout :: String
      , stderr :: String
      , exit :: CP.Exit
      }
spawn = spawn' UTF8 SIGTERM

spawn'
  :: Encoding
  -> Signal
  -> String
  -> Array String
  -> CP.SpawnOptions
  -> Aff
      { stdout :: String
      , stderr :: String
      , exit :: CP.Exit
      }
spawn' encoding killSignal cmd args options = makeAff \cb -> do
  stdoutRef <- new ""
  stderrRef <- new ""

  process <- CP.spawn cmd args options

  onDataString (CP.stdout process) encoding \string ->
    modify_ (_ <> string) stdoutRef

  onDataString (CP.stderr process) encoding \string ->
    modify_ (_ <> string) stderrRef

  CP.onError process $ cb <<< Left <<< CP.toStandardError

  CP.onExit process \exit -> do
    stdout <- read stdoutRef
    stderr <- read stderrRef
    cb <<< pure $ {stdout, stderr, exit}

  pure <<< effectCanceler <<< void $ CP.kill killSignal process
