module Sunde where

import Prelude

import Control.Monad.Aff (Aff, effCanceler, makeAff)
import Control.Monad.Eff.Exception (EXCEPTION)
import Control.Monad.Eff.Ref (REF, modifyRef, newRef, readRef)
import Data.Either (Either(..))
import Data.Posix.Signal (Signal(..))
import Node.ChildProcess as CP
import Node.Encoding (Encoding(..))
import Node.Stream (onDataString)

spawn
  :: forall e
   . String
  -> Array String
  -> CP.SpawnOptions
  -> Aff
      ( ref :: REF
      , exception :: EXCEPTION
      , cp :: CP.CHILD_PROCESS
      | e
      )
      { stdout :: String
      , stderr :: String
      , exit :: CP.Exit
      }
spawn = spawn' UTF8 SIGTERM

spawn'
  :: forall e
   . Encoding
  -> Signal
  -> String
  -> Array String
  -> CP.SpawnOptions
  -> Aff
      ( ref :: REF
      , exception :: EXCEPTION
      , cp :: CP.CHILD_PROCESS
      | e
      )
      { stdout :: String
      , stderr :: String
      , exit :: CP.Exit
      }
spawn' encoding killSignal cmd args options = makeAff \cb -> do
  stdoutRef <- newRef ""
  stderrRef <- newRef ""

  process <- CP.spawn cmd args options

  onDataString (CP.stdout process) encoding \string ->
    modifyRef stdoutRef $ (_ <> string)

  onDataString (CP.stderr process) encoding \string ->
    modifyRef stderrRef $ (_ <> string)

  CP.onError process $ cb <<< Left <<< CP.toStandardError

  CP.onExit process \exit -> do
    stdout <- readRef stdoutRef
    stderr <- readRef stderrRef
    cb <<< pure $ {stdout, stderr, exit}

  pure <<< effCanceler <<< void $ CP.kill killSignal process
