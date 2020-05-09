
#!/bin/bash
set -ev

#bringing network down and clearing volumes

docker-compose -f docker-compose.yaml down

docker volume prune

docker network prune

#clean

ITEMS=$(docker ps -a | awk '$2~/hyperledger/ {print $1}') 

if [ ! -z "$ITEMS" ]; then
    docker stop $(docker ps -a | awk '$2~/hyperledger/ {print $1}') 
    docker rm -f $(docker ps -a | awk '$2~/hyperledger/ {print $1}') $(docker ps -a | awk '{ print $1,$2 }' | grep dev-peer | awk '{print $1 }') || true
    docker rmi -f $(docker images | grep dev-peer | awk '{print $3}') || true
fi


# Creating network

#docker network create -d bridge net_hurley_dev_net
#docker volume create --name net_shared
#Bringing network Up with Previous Backup

COMPOSE_PROJECT_NAME=net docker-compose -f /home/angelo/hyperledger-fabric-network/restore-network.yaml up -d
COMPOSE_PROJECT_NAME=net docker-compose up -d --force-recreate
#sleep 10
#docker-compose -f /home/angelo/hyperledger-fabric-network/restore-network.yaml up -d --force-recreate

#docker-compose -f /home/angelo/hyperledger-fabric-network/docker-compose.yaml up -d

#COMPOSE_PROJECT_NAME=net docker-compose up -d

#docker start $(docker ps -a -q --filter "status=exited")
#docker start $(docker ps -a -q --filter "status=exited")
#sleep 10

USERS=0

function createchannel() {
    SERVER=$1
    CH=$2

    echo "Creating $CH channel block in peer $SERVER"
    docker exec $SERVER peer channel create  -o orderer.hurley.lab:7050 -c $CH -f /etc/hyperledger/configtx/$CH.tx
    docker exec $SERVER mv $CH.block /shared/

    # copy ch1.block to container
    #docker cp -a /home/angelo/hyperledger-fabric-network/backup/artifacts/config/ch1.tx  orderer.hurley.lab:/etc/hyperledger/configtx/ch1.tx

   # docker cp -a /home/angelo/hyperledger-fabric-network/backup/artifacts/config/ch1.tx  orderer.hurley.lab:/etc/hyperledger/configtx/ch1.tx
    #docker cp -a /home/angelo/hyperledger-fabric-network/backup/artifacts/config/genesis.block  orderer.hurley.lab:/etc/hyperledger/configtx/genesis.block

   # docker cp -a /home/angelo/hyperledger-fabric-network/backup/shared/shared/ch1.block  peer0.org1.hurley.lab:shared/ch1.block



}

function joinchannel() {
    echo "Joining $2 channel on peer $1"
    SERVER=$1
    CH=$2
    COUNTER=1
    MAX_RETRY=5
    DELAY="3"

    set -x
    output=$(docker exec $1 peer channel join -b /shared/$2.block && echo "pass" || echo "fail")
    set +x

    if [ "$output" == "fail" ]; then
        COUNTER=$(expr $COUNTER + 1)
        echo "$SERVER failed to join the channel, Retry after $DELAY seconds"
        sleep $DELAY
        joinchannel $SERVER $CH
    else
        COUNTER=1
    fi

}

function setanchor() {
    echo
    echo "Creating $2 anchor block in peer $1"
    docker exec $1 peer channel update  -o orderer.hurley.lab:7050 -c $2 -f /etc/hyperledger/configtx/$1.$2.tx

}

createchannel peer0.org1.hurley.lab ch1

#sleep 10

joinchannel peer0.org1.hurley.lab ch1
joinchannel peer0.org2.hurley.lab ch1

#setanchor peer0.org1.hurley.lab ch1
#setanchor peer0.org2.hurley.lab ch1

sleep 5

#Installing chaincode
bash installscript2.sh 

#sudo bash upgradescript.sh

#All done...
exit 1
