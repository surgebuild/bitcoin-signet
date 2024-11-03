FROM debian:buster-slim as builder

ARG BITCOIN_VERSION=${BITCOIN_VERSION:-"d8434da3c14e"}
ARG TARGETPLATFORM  

RUN apt-get update && \
  apt-get install -qq --no-install-recommends ca-certificates dirmngr gosu wget libc6 procps python3

WORKDIR /tmp

# Install bitcoin binaries
RUN case $TARGETPLATFORM in \
  linux/amd64) \
  echo "amd64" && export TRIPLET="x86_64-linux-gnu";; \
  linux/arm64) \
  echo "arm64" && export TRIPLET="aarch64-linux-gnu";; \
  esac && \
  BITCOIN_URL="https://github.com/benthecarman/bitcoin/releases/download/custom-signet-blocktime/bitcoin-${BITCOIN_VERSION}-${TRIPLET}.tar.gz" && \
  BITCOIN_FILE="bitcoin-${BITCOIN_VERSION}-${TRIPLET}.tar.gz" && \
  wget -qO "${BITCOIN_FILE}" "${BITCOIN_URL}" && \
  mkdir -p bin && \
  tar -xzvf "${BITCOIN_FILE}" -C /tmp/bin --strip-components=2 "bitcoin-${BITCOIN_VERSION}/bin/bitcoin-cli" "bitcoin-${BITCOIN_VERSION}/bin/bitcoind" "bitcoin-${BITCOIN_VERSION}/bin/bitcoin-wallet" "bitcoin-${BITCOIN_VERSION}/bin/bitcoin-util"

FROM debian:buster-slim as custom-signet-bitcoin

LABEL org.opencontainers.image.authors="Surge Build Team"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.source="https://github.com/surgebuild/bitcoin_signet"

ENV BITCOIN_DIR /root/.bitcoin 

ENV NBITS=${NBITS}
ENV SIGNETCHALLENGE=${SIGNETCHALLENGE}
ENV SIGNETBLOCKTIME=${SIGNETBLOCKTIME:-"10"}
ENV PRIVKEY=${PRIVKEY}
ENV RPCUSER=${RPCUSER:-"bitcoin"}
ENV RPCPASSWORD=${RPCPASSWORD:-"bitcoin"}
ENV DBCACHE=${DBCACHE:-"4096"} 
ENV COOKIEFILE=${COOKIEFILE:-"true"}
ENV ONIONPROXY=${ONIONPROXY:-""}
ENV TORPASSWORD=${TORPASSWORD:-""}
ENV TORCONTROL=${TORCONTROL:-""}
ENV I2PSAM=${I2PSAM:-""}
ENV UACOMMENT=${UACOMMENT:-"CustomSignet"}
ENV ZMQPUBRAWBLOCK=${ZMQPUBRAWBLOCK:-"tcp://0.0.0.0:28332"}
ENV ZMQPUBRAWTX=${ZMQPUBRAWTX:-"tcp://0.0.0.0:28333"}
ENV ZMQPUBHASHBLOCK=${ZMQPUBHASHBLOCK:-"tcp://0.0.0.0:28334"}
ENV RPCBIND=${RPCBIND:-"0.0.0.0:38332"}
ENV RPCALLOWIP=${RPCALLOWIP:-"0.0.0.0/0"}
ENV WHITELIST=${WHITELIST:-"0.0.0.0/0"}
ENV ADDNODE=${ADDNODE:-"192.241.131.95:38333"}
ENV BLOCKPRODUCTIONDELAY=${BLOCKPRODUCTIONDELAY:-"10"}
ENV MINERENABLED=${MINERENABLED:-"1"}
ENV MINETO=${MINETO:-"tb1qpynphh688rqnaek73pqm5759vzl53myua3gd25"}
ENV EXTERNAL_IP=${EXTERNAL_IP:-""}

VOLUME $BITCOIN_DIR
EXPOSE 28332 28333 28334 38332 38333 38334

RUN apt-get update && \
  apt-get install -qq --no-install-recommends procps python3 python3-pip jq && \
  apt-get clean

COPY --from=builder /tmp/bin /usr/local/bin
COPY docker-entrypoint.sh /usr/local/bin/entrypoint.sh
COPY miner_imports /usr/local/bin
COPY miner /usr/local/bin/miner
COPY *.sh /usr/local/bin/
COPY rpcauth.py /usr/local/bin/rpcauth.py

RUN pip3 install setuptools

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["run.sh"]
