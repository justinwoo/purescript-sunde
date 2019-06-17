module Sunde where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Posix.Signal (Signal(..))
import Effect.Aff (Aff, effectCanceler, makeAff)
import Effect.Ref (modify_, new, read)
import Node.ChildProcess as CP
import Node.Encoding (Encoding(..))
import Node.Stream (onDataString)
import Node.Stream as NS

spawn
  :: { cmd :: String, args :: Array String, stdin :: Maybe String }
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
  -> { cmd :: String, args :: Array String, stdin :: Maybe String }
  -> CP.SpawnOptions
  -> Aff
      { stdout :: String
      , stderr :: String
      , exit :: CP.Exit
      }
spawn' encoding killSignal {cmd, args, stdin} options = makeAff \cb -> do
  stdoutRef <- new ""
  stderrRef <- new ""

  process <- CP.spawn cmd args options

  case stdin of
    Just input -> do
      let write = CP.stdin process
      void $ NS.writeString write UTF8 input do
        NS.end write mempty
    Nothing -> pure unit

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
