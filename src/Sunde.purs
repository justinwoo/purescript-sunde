module Sunde where

import Prelude

import Data.Array as Array
import Data.Either (Either(..))
import Data.Foldable (for_)
import Data.Maybe (Maybe)
import Data.Posix.Signal (Signal(..))
import Effect.Aff (Aff, effectCanceler, makeAff)
import Effect.Ref as Ref
import Node.Buffer as Buffer
import Node.ChildProcess as CP
import Node.ChildProcess.Types (Exit)
import Node.Encoding (Encoding(..))
import Node.Errors.SystemError as SystemError
import Node.EventEmitter as EventEmitter
import Node.Stream as NS

spawn
  :: { cmd :: String, args :: Array String, stdin :: Maybe String }
  -> (CP.SpawnOptions -> CP.SpawnOptions)
  -> Aff
       { stdout :: String
       , stderr :: String
       , exit :: Exit
       }
spawn = spawn' UTF8 SIGTERM

spawn'
  :: Encoding
  -> Signal
  -> { cmd :: String, args :: Array String, stdin :: Maybe String }
  -> (CP.SpawnOptions -> CP.SpawnOptions)
  -> Aff
       { stdout :: String
       , stderr :: String
       , exit :: Exit
       }
spawn' encoding killSignal { cmd, args, stdin } modifyOptions = makeAff \cb -> do
  stdoutRef <- Ref.new []
  stderrRef <- Ref.new []

  process <- CP.spawn' cmd args modifyOptions

  for_ stdin \input -> do
    let writable = CP.stdin process
    void $ NS.writeString writable UTF8 input
    NS.end writable

  CP.stdout process # EventEmitter.on_ NS.dataH \buf ->
    Ref.modify_ (\ref' -> Array.snoc ref' buf) stdoutRef
  CP.stderr process # EventEmitter.on_ NS.dataH \buf ->
    Ref.modify_ (\ref' -> Array.snoc ref' buf) stderrRef

  process # EventEmitter.once_ CP.errorH (cb <<< Left <<< SystemError.toError)

  process # EventEmitter.once_ CP.exitH \exit -> do
    stdout <- Buffer.toString encoding =<< Buffer.concat =<< Ref.read stdoutRef
    stderr <- Buffer.toString encoding =<< Buffer.concat =<< Ref.read stderrRef
    cb <<< pure $ { stdout, stderr, exit }

  pure <<< effectCanceler <<< void $ CP.killSignal killSignal process
