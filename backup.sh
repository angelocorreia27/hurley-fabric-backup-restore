set -ev

sudo rm -rf backup
mkdir backup
#Copying Certificates and Configuration files
sleep 5
cp -r artifacts/crypto-config backup/artifacts
cp -r artifacts/config backup/artifacts

cd backup
mkdir peer0.org1
mkdir peer0.org2
mkdir shared
mkdir orderer
cd ..
#Copying Peer and orderer data
sleep 5

# peers and couchdb
sudo docker cp peer0.org1.hurley.lab:/var/hyperledger/production/ backup/peer0.org1/
sudo docker cp couchdb.peer0.org2.hurley.lab:/opt/couchdb/ backup/couchdb.peer0.org2/

sudo docker cp peer0.org2.hurley.lab:/var/hyperledger/production/ backup/peer0.org2/
sudo docker cp couchdb.peer0.org1.hurley.lab:/opt/couchdb/ backup/couchdb.peer0.org1/

sudo docker cp peer0.org1.hurley.lab:/shared/ backup/shared/
# orderers
sudo docker cp orderer.hurley.lab:/var/hyperledger/production/orderer backup/orderer/


#All done
exit 1
