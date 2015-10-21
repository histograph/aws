#!/usr/bin/env bash

# run as root
echo
echo "  ---%%%%%%%%%%%%%%%%%%%%%%%%%%---"
echo "----%%%%% INSTALLING NEO4J %%%%%----"
echo "  ---%%%%%%%%%%%%%%%%%%%%%%%%%%---"
echo

# install debian keys and UTF-8 locales
apt install debian-archive-keyring language-pack-UTF-8 -y

# import Neo4J signing key
# http://debian.neo4j.org/neotechnology.gpg.key
cat <<PGP_KEY | apt-key add -
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.11 (GNU/Linux)

mQINBFRO4UQBEADzzMOKKrxJ9bIzgLmMsTc/7E+h+7MeuHTEU79cynz9ORHPQTXY
56Cu05+PaAGWf+XiprEz2sYo0jtvPmK4aodp0j83ID2SPwZ4OsxL5NTBiXCHRxNz
0hG3Y/zl5EOtYMeTl4dq+S6TFNYNQGydet/f4tN+hFXTRKwFUzwIRqeVj1B0o+er
31TN8WUdrRBfYAif1l+NYWHCoa65k9dyc1/qLQy7RG+B7oFMFTCvmEm4BY9+joUl
Oah2fz10fIqRr4vjmFK3B5Hz3wAqOlojSG3XXJoLAlfZOwJ7NlqABku5D1YbeZR0
5ichch8gWxXzxndc6xeyYpiozb6OupF84l89qIgoPcYR78HWakHdinNXBJi8kyWt
JmZMVzMTAYmTjnfopSmcx94GE87/V99p5VTNp+eD6VKhRdh0rxBG/yvWGcqBavEV
woXEJwkutduPs6yx5JZpM8tHic6fRBF11Ec8au0OkK1OxzlZCsCq4VYZs9wzjuWe
Hvb6EkQEbjnDHhm9BsqfSGGkcKy1k2kZtroP3/u9sEzURFe7GCDktkD8H/2eoGcw
+s2pBPgYdkUDP71QcGgnIzBpFDqb8pL9w85VJKqRnxcb2rO7PLba0PtMj8yAyGC3
tfHa5/i6UTfK89sc0Z7/upeW2ZEhZxuZsVR8Zi5K4HlHYrK55zW1i5YcBwARAQAB
tDBOZW8gVGVjaG5vbG9neSBBZG1pbnMgPGFkbWluc0BuZW90ZWNobm9sb2d5LmNv
bT6JAj4EEwECACgFAlRO4UQCGwMFCQlmAYAGCwkIBwMCBhUIAgkKCwQWAgMBAh4B
AheAAAoJECbJXPIBGCJS8boQAMKNCnXpyvzqGKkI0lGXPmneXyNrMQ4xaLcPHRZx
tF1FZaTNks5Oe2UAQoHz8qom4ev+kQAwDwyqItciP3UgbHRGrXy6xItBeXMnLB77
chqJOwmvW12IlE9TxvhYJvuzmo+wG6REk6CGKUUGMhXPkZzWAu19cowSoG1MwpaT
XnCXuDNo874GMQ+NM484GpBMvgEHd7QfYgkx1iMa6StuX071/QHyLT9qUPV7pscV
+r5ijdvhlMvKfHWsuUPrQtxXN+C4Y197jA2PrTfnTBZPb7BkNpBQRyERQNNNhUsK
MJV6Hpt16iHjAif07V2fkKhKt9tzSGtwXrYldsLcOyx3PlweeJEpkr4x7jTtSKPV
fXr2A2uipmQqe8L9BRvKKaj+uNezHACJOtg5XHjonLP01MqLixfhvXnMVRyBjWNy
zhBsgcJ8biI5fquyF9rs5yGnwL4vVsV6RkF/zZ3i0QtVFUgG7++rK88OeVwqYokd
e09LAl1lUzKz8Fnfw8RBRjod6lLvWFHImSD5gqN1IWs1b+pTSHYc1YHY0FcAIryP
ZnQiKfg8NZSHhcQ8iWsZ0L4BOzu8teA6Y/A724b6mnlZ1UCNMaSe3A1YIU6QEAqj
3iWKpPfXUgCqT85ByFOnYuqiW+YFV18Z/ISOZxO1v+rg5qRc0+W3PUwZX4HMUa8B
r6RX
=j3eL
-----END PGP PUBLIC KEY BLOCK-----
PGP_KEY

# add neo4 repository
echo 'deb http://debian.neo4j.org/repo stable/' > /etc/apt/sources.list.d/neo4j.list

# update and install
apt update -y
apt upgrade -y
apt install curl neo4j -y

# disable Neo4J auth
sed -i_ -e 's/auth_enabled=true/auth_enabled=false/' \
	/etc/neo4j/neo4j-server.properties

# listen on 0.0.0.0
sed -i_ -e 's/#org\.neo4j\.server\.webserver\.address=0\.0\.0\.0/org.neo4j.server.webserver.address=0.0.0.0/' \
	/etc/neo4j/neo4j-server.properties

# enable histograph plugin
echo "org.neo4j.server.thirdparty_jaxrs_classes=org.waag.histograph.plugins=/histograph" >> /etc/neo4j/neo4j-server.properties

# TODO change data dir? or mount here `/var/lib/neo4j/data`

# install git, maven
apt install git maven openjdk-7-jdk -y
git clone https://github.com/histograph/neo4j-plugin.git /root/neo4j-plugin

# build and install plugin
cd /root/neo4j-plugin
mvn package
chown neo4j:adm /root/neo4j-plugin/target/histograph-plugin-*.jar
cp /root/neo4j-plugin/target/histograph-plugin-*.jar /usr/share/neo4j/plugins

# restart
service neo4j-service restart

# function to test if http is up
http_okay () {
  res=`curl -fsI $1 | grep HTTP/1.1 | awk {'print $2'}`
  if [ "$res" = "200" ];
  then
    echo testing $1, status is: OK;
    return 0;
  else
    echo testing $1, status is: not okay;
    return 1;
  fi
}

# wait until neo4j is up
until http_okay localhost:7474;
do
  sleep 3s;
done;

# setup schema
neo4j-shell -c "CREATE CONSTRAINT ON (n:_) ASSERT n.id IS UNIQUE;"
