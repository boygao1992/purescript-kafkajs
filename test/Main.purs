module Test.Main (main) where

import Prelude

import Control.Monad.Error.Class as Control.Monad.Error.Class
import Control.Monad.Rec.Class as Control.Monad.Rec.Class
import Data.Either as Data.Either
import Data.Foldable as Data.Foldable
import Data.Int as Data.Int
import Effect (Effect)
import Effect.Aff as Effect.Aff
import Effect.Class as Effect.Class
import Effect.Class.Console as Effect.Class.Console
import Effect.Exception as Effect.Exception
import Node.ChildProcess as Node.ChildProcess

-- | `checkIfKafkaInstanceIsReady` throws an exception if not ready (either `docker-compose logs` or `grep` fails)
checkIfKafkaInstanceIsReady :: String -> Effect Unit
checkIfKafkaInstanceIsReady containerName = do
  void $ Node.ChildProcess.execSync cmd
    Node.ChildProcess.defaultExecSyncOptions
  where
  cmd :: String
  cmd =
    """
docker-compose \
  -f ./kafkajs/docker-compose.2_4.yml \
  logs """ <> containerName <>
      """ \
  | grep "started (kafka.server.KafkaServer)"
"""

dockerComposeDown :: Effect Unit
dockerComposeDown = do
  Effect.Class.Console.log "Stopping Zookeeper and Kafka instances"
  void $ Node.ChildProcess.execSync cmd
    Node.ChildProcess.defaultExecSyncOptions
  Effect.Class.Console.log "Zookeeper and Kafka instances stopped"
  where
  cmd :: String
  cmd =
    """
docker-compose \
  -f ./kafkajs/docker-compose.2_4.yml \
  down \
  --remove-orphans
"""

dockerComposeUp :: Effect Unit
dockerComposeUp = do
  Effect.Class.Console.log "Starting Zookeeper and Kafka instances"
  void $ Node.ChildProcess.execSync cmd
    Node.ChildProcess.defaultExecSyncOptions
  Effect.Class.Console.log do
    "Zookeeper and Kafka instances started"
  where
  cmd :: String
  cmd =
    """
docker-compose \
  -f ./kafkajs/docker-compose.2_4.yml \
  up \
  --force-recreate \
  -d
"""

main :: Effect Unit
main = Effect.Aff.runAff_ reraiseException do
  Effect.Aff.bracket acquire release \_ -> do
    Effect.Class.liftEffect waitForKafka
    pure unit
  where
  acquire :: Effect.Aff.Aff Unit
  acquire = Effect.Class.liftEffect do
    dockerComposeUp

  reraiseException :: forall a. Data.Either.Either Effect.Aff.Error a -> Effect Unit
  reraiseException = case _ of
    Data.Either.Left error -> do
      Effect.Exception.throwException error
    Data.Either.Right _ -> pure unit

  release :: Unit -> Effect.Aff.Aff Unit
  release _ = Effect.Class.liftEffect do
    dockerComposeDown

retry ::
  forall a e m.
  Control.Monad.Rec.Class.MonadRec m =>
  Control.Monad.Error.Class.MonadError e m =>
  Int ->
  m Unit ->
  m a ->
  m a
retry limit betweenRetries effect = Control.Monad.Rec.Class.tailRecM go 1
  where
  go ::
    Int ->
    m (Control.Monad.Rec.Class.Step Int a)
  go count
    | count >= limit = do
        result <- effect
        pure $ Control.Monad.Rec.Class.Done result
    | otherwise = do
        result <- Control.Monad.Error.Class.try effect
        case result of
          Data.Either.Left _ -> do
            betweenRetries
            pure $ Control.Monad.Rec.Class.Loop (count + 1)
          Data.Either.Right a -> do
            pure $ Control.Monad.Rec.Class.Done a

sleep :: Int -> Effect Unit
sleep seconds = do
  void $ Node.ChildProcess.execSync cmd
    Node.ChildProcess.defaultExecSyncOptions
  where
  cmd :: String
  cmd = "sleep " <> Data.Int.toStringAs Data.Int.decimal seconds

waitForKafka :: Effect Unit
waitForKafka = do
  Effect.Class.liftEffect
    $ Data.Foldable.for_ brokerNames waitForKafkaInstance
  where
  brokerNames :: Array String
  brokerNames =
    [ "kafka1"
    , "kafka2"
    , "kafka3"
    ]

waitForKafkaInstance :: String -> Effect Unit
waitForKafkaInstance containerName = do
  Effect.Class.Console.log do
    "Waiting for " <> containerName <> " to be ready"
  retry retryLimit (sleep 5) do
    checkIfKafkaInstanceIsReady containerName
  Effect.Class.Console.log do
    containerName <> " is ready"
  where
  retryLimit :: Int
  retryLimit = 30

