# Shell Commands

start 1 `zookeeper` and 3 `kafka` brokers in docker containers by `docker-compose up`
- use `-d` (detached) if you don't want to see logs from containers immediately

`docker-compose -f ./kafkajs/docker-compose.2_4.yml up -d`

follow console logs if `docker-compose up` with `-d` (detached)

`docker-compose -f ./kafkajs/docker-compose.2_4.yml logs -f`

create `test1` topic with 3 partition and 3 replica (through broker 1 `kafka1` inside its docker container) by `kafka-topics --create`
- since the command is executed inside the docker container, `--bootstrap-server` should point to the internal URL (`kafka1:29092` vs external URL `localhost:9092`)

`docker-compose -f ./kafkajs/docker-compose.2_4.yml exec kafka1 kafka-topics --create --replication-factor 3 --partitions 3 --topic test1 --bootstrap-server kafka1:29092`

list existing topics by `kafka-topics --list`

`docker-compose -f ./kafkajs/docker-compose.2_4.yml exec kafka1 kafka-topics --list --bootstrap-server kafka1:29092`

inspect `test1` topic by `kafka-topics --describe`

`docker-compose -f ./kafkajs/docker-compose.2_4.yml exec kafka1 kafka-topics --describe --topic test1 --bootstrap-server kafka1:29092`

which should return a list like the following

```
Topic: test1	PartitionCount: 3	ReplicationFactor: 3	Configs: 
	Topic: test1	Partition: 0	Leader: 2	Replicas: 2,1,0	Isr: 2,1,0
	Topic: test1	Partition: 1	Leader: 1	Replicas: 1,0,2	Isr: 1,0,2
	Topic: test1	Partition: 2	Leader: 0	Replicas: 0,2,1	Isr: 0,2,1
```

- `Partition`
  - partition ID
  - to decide which partition a message should go
    - users could compute the partition index for a message by a hashing algorithm of their own choice and explicitly set it in the message payload
    - if partition index is not specified, `kafkajs` applies `murmur2` hash function over message `key`
    - round-robin if neither `partition` nor `key` is specified
- `Leader`
  - ID of a single broker that possesses the replica copy leader of the partition
- `Replicas`
  - IDs of brokers that possess a replica copy
- `Isr` (in-sync Replicas)
  - IDs of brokers that possess a replica copy and are not lagging behind the leader

start console producer publishing messages to  `test1` topic
- press `Ctrl-C` to exit once you are done

`docker-compose -f ./kafkajs/docker-compose.2_4.yml exec kafka1 kafka-console-producer --topic test1 --broker-list kafka1:29092`

start console consumer receiving all messages from `test1` topic
- press `Ctrl-C` to exit once you are done

`docker-compose -f ./kafkajs/docker-compose.2_4.yml exec kafka1 kafka-console-consumer --topic test1 --from-beginning --bootstrap-server kafka1:29092`

