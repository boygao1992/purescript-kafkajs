module Test.Main (main) where

import Prelude

import Control.Monad.Error.Class as Control.Monad.Error.Class
import Control.Monad.Rec.Class as Control.Monad.Rec.Class
import Data.Array as Data.Array
import Data.Either as Data.Either
import Data.Foldable as Data.Foldable
import Data.Int as Data.Int
import Data.Maybe as Data.Maybe
import Data.Traversable as Data.Traversable
import Effect (Effect)
import Effect.Aff as Effect.Aff
import Effect.Class as Effect.Class
import Effect.Class.Console as Effect.Class.Console
import Effect.Exception as Effect.Exception
import Effect.Ref as Effect.Ref
import Effect.Timer as Effect.Timer
import Kafka.Admin as Kafka.Admin
import Kafka.Consumer as Kafka.Consumer
import Kafka.FFI.Consumer as Kafka.FFI.Consumer
import Kafka.FFI.Kafka as Kafka.FFI.Kafka
import Kafka.Kafka as Kafka.Kafka
import Kafka.Producer as Kafka.Producer
import Node.Buffer as Node.Buffer
import Node.ChildProcess as Node.ChildProcess
import Node.Encoding as Node.Encoding
import Test.Unit as Test.Unit
import Test.Unit.Assert as Test.Unit.Assert
import Test.Unit.Output.Fancy as Test.Unit.Output.Fancy

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
    runTest suiteMain
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

newKafka :: Effect.Aff.Aff Kafka.FFI.Kafka.Kafka
newKafka = do
  Effect.Class.liftEffect $
    Kafka.Kafka.newKafka
      { brokers: Kafka.Kafka.KafkaConfigBrokersPure brokers
      , clientId: Data.Maybe.Just clientId
      , logLevel: Data.Maybe.Just Kafka.Kafka.LogLevelNothing
      }
  where
  brokers :: Array String
  brokers =
    [ "localhost:9092"
    , "localhost:9095"
    , "localhost:9098"
    ]

  clientId :: String
  clientId = "Test.Main"

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

-- | NOTE `Test.Unit.Main.runTest` could bypass the cleanup step in
-- |  `Effect.Aff.bracket` by early termination of the process with
-- | `Test.Unit.Main.exit 1` when there are failed tests.
-- | See https://github.com/bodil/purescript-test-unit/blob/b0229a121537de9e47a0b0705005dd7b81c2c160/src/Test/Unit/Main.purs#L38
-- |
-- | Instead of terminating the process, we raise an exception in `Aff`
-- | which can be captured by `Effect.Aff.bracket`.
runTest :: Test.Unit.TestSuite -> Effect.Aff.Aff Unit
runTest suite = runTestWith Test.Unit.Output.Fancy.runTest
  where
  runTestWith :: (Test.Unit.TestSuite -> Effect.Aff.Aff Test.Unit.TestList) -> Effect.Aff.Aff Unit
  runTestWith runner = do
    results <- runner (Test.Unit.filterTests suite) >>= Test.Unit.collectResults
    let errs = Test.Unit.keepErrors results
    when (Data.Foldable.length errs > 0) do
      Effect.Aff.throwError
        $ Effect.Aff.error "Test.Main.runTest: some tests failed"

sleep :: Int -> Effect Unit
sleep seconds = do
  void $ Node.ChildProcess.execSync cmd
    Node.ChildProcess.defaultExecSyncOptions
  where
  cmd :: String
  cmd = "sleep " <> Data.Int.toStringAs Data.Int.decimal seconds

suiteMain :: Test.Unit.TestSuite
suiteMain = do
  testProduceConsumeRoundtrip
  Test.Unit.suite "Kafka.Consumer" do
    Test.Unit.suite "Kafka.Consumer.seek" do
      testConsumerSeekWithTwoPartitions

testConsumerSeekWithTwoPartitions :: Test.Unit.TestSuite
testConsumerSeekWithTwoPartitions =
  Test.Unit.test "with two partitions" do
    let
      groupId :: String
      groupId = "testConsumerSeekWithTwoPartitions-groupId"

      messages :: Array { key :: String, partition :: Int, value :: String }
      messages =
        [ { key: "key-1", partition: 0, value: "value-A" }
        , { key: "key-2", partition: 1, value: "value-B" }
        , { key: "key-3", partition: 0, value: "value-C" }
        , { key: "key-4", partition: 1, value: "value-D" }
        , { key: "key-5", partition: 0, value: "value-E" }
        , { key: "key-6", partition: 1, value: "value-F" }
        ]

      numPartitions :: Int
      numPartitions = 2

      topic :: String
      topic = "testConsumerSeekWithTwoPartitions-topic"

      topicPartitionOffsets :: Array Kafka.FFI.Consumer.TopicPartitionOffset
      topicPartitionOffsets =
        [ { offset: "1", partition: 0, topic }
        , { offset: "2", partition: 1, topic }
        ]
    kafka <- newKafka
    admin <- Effect.Class.liftEffect $
      Kafka.Admin.admin kafka
    Effect.Aff.bracket (Kafka.Admin.connect admin) (\_ -> Kafka.Admin.disconnect admin) \_ -> do
      created <- Kafka.Admin.createTopics admin
        { timeout: Data.Maybe.Nothing
        , topics:
            [ { numPartitions: Data.Maybe.Just numPartitions
              , replicationFactor: Data.Maybe.Just 3
              , topic
              }
            ]
        , validateOnly: Data.Maybe.Nothing
        , waitForLeaders: Data.Maybe.Nothing
        }
      Test.Unit.Assert.assert "Topic is already created" created
    producer <- Effect.Class.liftEffect $
      Kafka.Producer.producer kafka
        { allowAutoTopicCreation: Data.Maybe.Just false
        , createPartitioner: Data.Maybe.Nothing
        , idempotent: Data.Maybe.Nothing
        , maxInFlightRequests: Data.Maybe.Nothing
        , metadataMaxAge: Data.Maybe.Nothing
        , transactionTimeout: Data.Maybe.Nothing
        , transactionalId: Data.Maybe.Nothing
        }
    Effect.Aff.bracket (Kafka.Producer.connect producer) (\_ -> Kafka.Producer.disconnect producer) \_ -> do
      void $ Kafka.Producer.send producer
        { acks: Data.Maybe.Nothing
        , compression: Data.Maybe.Nothing
        , messages: messages <#> \message ->
            { headers: Data.Maybe.Nothing
            , key: Data.Maybe.Just $ Kafka.Producer.String message.key
            , partition: Data.Maybe.Just message.partition
            , timestamp: Data.Maybe.Nothing
            , value: Data.Maybe.Just $ Kafka.Producer.String message.value
            }
        , timeout: Data.Maybe.Nothing
        , topic
        }
    receivedRef <- Effect.Class.liftEffect $
      Effect.Ref.new []
    consumer <- Effect.Class.liftEffect $
      Kafka.Consumer.consumer kafka
        { allowAutoTopicCreation: Data.Maybe.Just false
        , groupId
        , heartbeatInterval: Data.Maybe.Nothing
        , maxBytes: Data.Maybe.Nothing
        , maxBytesPerPartition: Data.Maybe.Nothing
        , maxInFlightRequests: Data.Maybe.Nothing
        , maxWaitTime: Data.Maybe.Nothing
        , metadataMaxAge: Data.Maybe.Nothing
        , minBytes: Data.Maybe.Nothing
        , partitionAssigners: Data.Maybe.Nothing
        , readUncommitted: Data.Maybe.Nothing
        , rebalanceTimeout: Data.Maybe.Nothing
        , sessionTimeout: Data.Maybe.Nothing
        }
    Effect.Aff.bracket (Kafka.Consumer.connect consumer) (\_ -> Kafka.Consumer.disconnect consumer) \_ -> do
      Kafka.Consumer.subscribe consumer
        { fromBeginning: Data.Maybe.Just true
        , topics: [ Kafka.Consumer.TopicName topic ]
        }
      fiberRun <- Effect.Aff.forkAff $ Kafka.Consumer.run consumer
        { autoCommit: Data.Maybe.Nothing
        , consume: Kafka.Consumer.EachBatch
            { autoResolve: Data.Maybe.Just true
            , handler: \eachBatchPayload -> do
                isStale <- Effect.Class.liftEffect eachBatchPayload.isStale
                when (not isStale) do
                  (newMessages :: Array { key :: String, partition :: Int, value :: String }) <-
                    map Data.Array.catMaybes
                      $ Data.Traversable.for eachBatchPayload.batch.messages \message -> do
                          let
                            maybeKeyValue :: Data.Maybe.Maybe { key :: Node.Buffer.Buffer, value :: Node.Buffer.Buffer }
                            maybeKeyValue = do
                              key <- message.key
                              value <- message.value
                              pure { key, value }
                          Data.Traversable.for maybeKeyValue \keyValue -> do
                            key <- Effect.Class.liftEffect $
                              Node.Buffer.toString Node.Encoding.UTF8 keyValue.key
                            value <- Effect.Class.liftEffect $
                              Node.Buffer.toString Node.Encoding.UTF8 keyValue.value
                            pure { key, partition: eachBatchPayload.batch.partition, value }
                  Effect.Class.liftEffect $
                    Effect.Ref.modify_ (_ <> newMessages) receivedRef
            }
        , partitionsConsumedConcurrently: Data.Maybe.Nothing
        }
      Effect.Class.liftEffect $
        Data.Foldable.for_ topicPartitionOffsets \topicPartitionOffset ->
          Kafka.Consumer.seek consumer topicPartitionOffset
      waitForConsumerToJoinGroup consumer
      Effect.Aff.joinFiber fiberRun
      waitForMessages 3 $ Effect.Class.liftEffect do
        received <- Effect.Ref.read receivedRef
        pure $ Data.Array.length received
    received <- Effect.Class.liftEffect $
      Effect.Ref.read receivedRef
    Test.Unit.Assert.equal
      [ { key: "key-3", partition: 0, value: "value-C" }
      , { key: "key-5", partition: 0, value: "value-E" }
      ]
      (Data.Array.filter (\x -> x.partition == 0) received)
    Test.Unit.Assert.equal
      [ { key: "key-6", partition: 1, value: "value-F" }
      ]
      (Data.Array.filter (\x -> x.partition == 1) received)

testProduceConsumeRoundtrip :: Test.Unit.TestSuite
testProduceConsumeRoundtrip = do
  Test.Unit.test "produce-consume roundtrip" do
    let
      groupId :: String
      groupId = "testProduceConsumeRoundtrip-groupId"

      messages :: Array { key :: String, value :: String }
      messages =
        [ { key: "key-1", value: "value-A" }
        , { key: "key-2", value: "value-B" }
        , { key: "key-3", value: "value-C" }
        ]

      topic :: String
      topic = "testProduceConsumeRoundtrip-topic"

    kafka <- newKafka
    admin <- Effect.Class.liftEffect $
      Kafka.Admin.admin kafka
    Effect.Aff.bracket (Kafka.Admin.connect admin) (\_ -> Kafka.Admin.disconnect admin) \_ -> do
      created <- Kafka.Admin.createTopics admin
        { timeout: Data.Maybe.Nothing
        , topics:
            [ { numPartitions: Data.Maybe.Just 1
              , replicationFactor: Data.Maybe.Just 3
              , topic
              }
            ]
        , validateOnly: Data.Maybe.Nothing
        , waitForLeaders: Data.Maybe.Nothing
        }
      Test.Unit.Assert.assert "Topic is already created" created
    producer <- Effect.Class.liftEffect $
      Kafka.Producer.producer kafka
        { allowAutoTopicCreation: Data.Maybe.Just false
        , createPartitioner: Data.Maybe.Nothing
        , idempotent: Data.Maybe.Nothing
        , maxInFlightRequests: Data.Maybe.Nothing
        , metadataMaxAge: Data.Maybe.Nothing
        , transactionTimeout: Data.Maybe.Nothing
        , transactionalId: Data.Maybe.Nothing
        }
    Effect.Aff.bracket (Kafka.Producer.connect producer) (\_ -> Kafka.Producer.disconnect producer) \_ -> do
      void $ Kafka.Producer.send producer
        { acks: Data.Maybe.Nothing
        , compression: Data.Maybe.Nothing
        , messages: messages <#> \message ->
            { headers: Data.Maybe.Nothing
            , key: Data.Maybe.Just $ Kafka.Producer.String message.key
            , partition: Data.Maybe.Nothing
            , timestamp: Data.Maybe.Nothing
            , value: Data.Maybe.Just $ Kafka.Producer.String message.value
            }
        , timeout: Data.Maybe.Nothing
        , topic
        }
    receivedRef <- Effect.Class.liftEffect $
      Effect.Ref.new []
    consumer <- Effect.Class.liftEffect $
      Kafka.Consumer.consumer kafka
        { allowAutoTopicCreation: Data.Maybe.Just false
        , groupId
        , heartbeatInterval: Data.Maybe.Nothing
        , maxBytes: Data.Maybe.Nothing
        , maxBytesPerPartition: Data.Maybe.Nothing
        , maxInFlightRequests: Data.Maybe.Nothing
        , maxWaitTime: Data.Maybe.Nothing
        , metadataMaxAge: Data.Maybe.Nothing
        , minBytes: Data.Maybe.Nothing
        , partitionAssigners: Data.Maybe.Nothing
        , readUncommitted: Data.Maybe.Nothing
        , rebalanceTimeout: Data.Maybe.Nothing
        , sessionTimeout: Data.Maybe.Nothing
        }
    Effect.Aff.bracket (Kafka.Consumer.connect consumer) (\_ -> Kafka.Consumer.disconnect consumer) \_ -> do
      Kafka.Consumer.subscribe consumer
        { fromBeginning: Data.Maybe.Just true
        , topics: [ Kafka.Consumer.TopicName topic ]
        }
      fiberRun <- Effect.Aff.forkAff $ Kafka.Consumer.run consumer
        { autoCommit: Data.Maybe.Nothing
        , consume: Kafka.Consumer.EachBatch
            { autoResolve: Data.Maybe.Just true
            , handler: \eachBatchPayload -> do
                (newMessages :: Array { key :: String, value :: String }) <-
                  map Data.Array.catMaybes
                    $ Data.Traversable.for eachBatchPayload.batch.messages \message -> do
                        let
                          maybeKeyValue :: Data.Maybe.Maybe { key :: Node.Buffer.Buffer, value :: Node.Buffer.Buffer }
                          maybeKeyValue = do
                            key <- message.key
                            value <- message.value
                            pure { key, value }
                        Data.Traversable.for maybeKeyValue \keyValue -> do
                          key <- Effect.Class.liftEffect $
                            Node.Buffer.toString Node.Encoding.UTF8 keyValue.key
                          value <- Effect.Class.liftEffect $
                            Node.Buffer.toString Node.Encoding.UTF8 keyValue.value
                          pure { key, value }
                Effect.Class.liftEffect $
                  Effect.Ref.modify_ (_ <> newMessages) receivedRef
            }
        , partitionsConsumedConcurrently: Data.Maybe.Nothing
        }
      waitForConsumerToJoinGroup consumer
      Effect.Aff.joinFiber fiberRun
      waitForMessages (Data.Array.length messages) $ Effect.Class.liftEffect do
        received <- Effect.Ref.read receivedRef
        pure $ Data.Array.length received
    received <- Effect.Class.liftEffect $
      Effect.Ref.read receivedRef
    Test.Unit.Assert.equal messages received

waitForConsumerToJoinGroup :: Kafka.FFI.Consumer.Consumer -> Effect.Aff.Aff Unit
waitForConsumerToJoinGroup consumer = do
  Effect.Aff.makeAff \callback -> do
    timeoutId <- Effect.Timer.setTimeout 10000 do
      callback $ Data.Either.Left
        $ Effect.Aff.error "waitForConsumerToJoinGroup timeout"
    onCrash <- Kafka.Consumer.onCrash consumer \event -> do
      Effect.Timer.clearTimeout timeoutId
      callback $ Data.Either.Left event.error
    onGroupJoin <- Kafka.Consumer.onGroupJoin consumer \_ -> do
      Effect.Timer.clearTimeout timeoutId
      callback $ Data.Either.Right unit
    pure $ Effect.Aff.Canceler \_ -> Effect.Class.liftEffect do
      Effect.Timer.clearTimeout timeoutId
      onCrash.removeListener
      onGroupJoin.removeListener

waitForMessages ::
  Int ->
  Effect.Aff.Aff Int ->
  Effect.Aff.Aff Unit
waitForMessages messageCount getReceivedCount = do
  retry retryLimit (Effect.Aff.delay (Effect.Aff.Milliseconds 1000.0)) do
    receivedCount <- getReceivedCount
    when (receivedCount < messageCount) do
      Effect.Aff.throwError
        $ Effect.Aff.error "didn't receive the expected number of messages"
  where
  retryLimit :: Int
  retryLimit = 5

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
