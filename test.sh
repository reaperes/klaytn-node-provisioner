#!/usr/bin/env bash-8-35 bin]$ cat kend

BIN=$(cd "$(dirname $0)"; pwd)
CMD_HOME=$(dirname $BIN)
CONF=$CMD_HOME/conf
STOP_TIMEOUT=10 # seconds to wait for a clean exit

source $CONF/kend.conf

if [ -z $DATA_DIR ]; then
    echo
    echo "  [ERROR] : DATA_DIR in conf/kend.conf is not defined."
    exit 1
fi

if [ ! -d $DATA_DIR ]; then
    echo
    echo "  [ERROR] : Genesis block is not initiated: [conf/kend.conf - DATA_DIR=$DATA_DIR]"
    exit 1
fi

pidfile=$DATA_DIR/kend.pid

__pid_run() {
    unset pid
    if [ ! -f $pidfile ]; then
        return
    fi
    PID_NUM=$(eval "cat $pidfile")
    if [[ ! -z "$PID_NUM" ]]; then
        export pid=$(eval "ps -p $PID_NUM -o pid=")
    fi
}

__kill_timeout() {
    local PIDNUM=$1
    kill $PIDNUM
    for i in `seq 0 100 $((1000 * $STOP_TIMEOUT))`; do
        if ! kill -0 $PIDNUM 2> /dev/null; then
            echo "OK"
            return
        fi
        sleep 0.1
    done
    kill -9 $PIDNUM && echo "Killed"
}

__check_option() {
    if [ ! -d $LOG_DIR ]; then
        mkdir -p $LOG_DIR
    fi

    set -f
    OPTIONS=""

    if [[ ! -z $METRICS ]] && [[ $METRICS -eq 1 ]]; then
        OPTIONS="$OPTIONS --metrics"
    fi

    if [[ ! -z $PROMETHEUS ]] && [[ $PROMETHEUS -eq 1 ]]; then
        OPTIONS="$OPTIONS --prometheus"
    fi

    if [[ ! -z $DB_NO_PARALLEL_WRITE ]] && [[ $DB_NO_PARALLEL_WRITE -eq 1 ]]; then
        OPTIONS="$OPTIONS --db.no-parallel-write"
    fi

    if [[ ! -z $MULTICHANNEL ]] && [[ $MULTICHANNEL -eq 1 ]]; then
        OPTIONS="$OPTIONS --multichannel"
    fi

    if [[ ! -z $RPC_ENABLE ]] && [[ $RPC_ENABLE -eq 1 ]]; then
        OPTIONS="$OPTIONS --rpc"
        if [ ! -z $RPC_API ]; then
            OPTIONS="$OPTIONS --rpcapi $RPC_API"
        fi
        if [ ! -z $RPC_PORT ]; then
            OPTIONS="$OPTIONS --rpcport $RPC_PORT"
        fi
        if [ ! -z $RPC_ADDR ]; then
            OPTIONS="$OPTIONS --rpcaddr $RPC_ADDR"
        fi
        if [ ! -z $RPC_CORSDOMAIN ]; then
            OPTIONS="$OPTIONS --rpccorsdomain $RPC_CORSDOMAIN"
        fi
        if [ ! -z $RPC_VHOSTS ]; then
            OPTIONS="$OPTIONS --rpcvhosts $RPC_VHOSTS"
        fi
    fi

    if [[ ! -z $WS_ENABLE ]] && [[ $WS_ENABLE -eq 1 ]]; then
        OPTIONS="$OPTIONS --ws"
        if [ ! -z $WS_API ]; then
            OPTIONS="$OPTIONS --wsapi $WS_API"
        fi
        if [ ! -z $WS_PORT ]; then
            OPTIONS="$OPTIONS --wsport $WS_PORT"
        fi
        if [ ! -z $WS_ADDR ]; then
            OPTIONS="$OPTIONS --wsaddr $WS_ADDR"
        fi
        if [ ! -z $WS_ORIGINS ]; then
            OPTIONS="$OPTIONS --wsorigins $WS_ORIGINS"
        fi
    fi

    # Cypress network => NETWORK_ID is null && NETWORK = "cypress"
    # Baobab network => NETWORK_ID is null && NETWORK = "baobab"
    # Else => private network
    if [[ -z $NETWORK_ID ]]; then
        if [[ $NETWORK == "baobab" ]]; then
            OPTIONS="$OPTIONS --baobab"
        elif [[ $NETWORK == "cypress" ]]; then
            OPTIONS="$OPTIONS --cypress"
        else
            echo
            echo "[ERROR] network id is not specified and network is not available."
            echo "Available network: baobab, cypress"
            exit 1
        fi
    else
        OPTIONS="$OPTIONS --networkid $NETWORK_ID"
        echo "[INFO] creating a private network: $NETWORK_ID"
        if [[ ! -z $NETWORK ]]; then
            echo
            echo "[WARN] ignoring the specified network: $NETWORK"
        fi
    fi

    if [ ! -z $DATA_DIR ]; then
        OPTIONS="$OPTIONS --datadir $DATA_DIR"
    fi

    if [ ! -z $PORT ]; then
        OPTIONS="$OPTIONS --port $PORT"
    fi

    if [ ! -z $SUBPORT ]; then
        OPTIONS="$OPTIONS --subport $SUBPORT"
    fi

    if [ ! -z $SERVER_TYPE ]; then
        OPTIONS="$OPTIONS --srvtype $SERVER_TYPE"
    fi

    if [ ! -z $VERBOSITY ]; then
        OPTIONS="$OPTIONS --verbosity $VERBOSITY"
    fi

    if [ ! -z $TXPOOL_EXEC_SLOTS_ALL ]; then
        OPTIONS="$OPTIONS --txpool.exec-slots.all $TXPOOL_EXEC_SLOTS_ALL"
    fi

    if [ ! -z $TXPOOL_NONEXEC_SLOTS_ALL ]; then
        OPTIONS="$OPTIONS --txpool.nonexec-slots.all $TXPOOL_NONEXEC_SLOTS_ALL"
    fi

    if [ ! -z $TXPOOL_EXEC_SLOTS_ACCOUNT ]; then
        OPTIONS="$OPTIONS --txpool.exec-slots.account $TXPOOL_EXEC_SLOTS_ACCOUNT"
    fi

    if [ ! -z $TXPOOL_NONEXEC_SLOTS_ACCOUNT ]; then
        OPTIONS="$OPTIONS --txpool.nonexec-slots.account $TXPOOL_NONEXEC_SLOTS_ACCOUNT"
    fi

    if [ ! -z $SYNCMODE ]; then
        OPTIONS="$OPTIONS --syncmode $SYNCMODE"
    fi

    if [ ! -z $MAXCONNECTIONS ]; then
        OPTIONS="$OPTIONS --maxconnections $MAXCONNECTIONS"
    fi

    if [ ! -z $LDBCACHESIZE ]; then
        OPTIONS="$OPTIONS --db.leveldb.cache-size $LDBCACHESIZE"
    fi

    if [[ ! -z $SC_MAIN_BRIDGE ]] && [[ $SC_MAIN_BRIDGE -eq 1 ]]; then
        OPTIONS="$OPTIONS --mainbridge --mainbridgeport $SC_MAIN_BRIDGE_PORT"
        if [[ ! -z $SC_MAIN_BRIDGE_INDEXING ]] && [[ $SC_MAIN_BRIDGE_INDEXING -eq 1 ]]; then
            OPTIONS="$OPTIONS --childchainindexing"
        fi
    fi

    if [[ ! -z $NO_DISCOVER ]] && [[ $NO_DISCOVER -eq 1 ]]; then
        OPTIONS="$OPTIONS --nodiscover"
    fi

    if [[ ! -z $BOOTNODES ]] && [[ $BOOTNODES != "" ]]; then
        OPTIONS="$OPTIONS --bootnodes $BOOTNODES"
    fi

    if [[ ! -z $ADDITIONAL ]] && [[ $ADDITIONAL != "" ]]; then
        OPTIONS="$OPTIONS $ADDITIONAL"
    fi

    if [[ ! -z $AUTO_RESTART ]] && [[ $AUTO_RESTART -eq 1 ]]; then
        OPTIONS="$OPTIONS --autorestart.enable"
    fi

    if [[ ! -z $DB_TYPE ]] && [[ $DB_TYPE != "" ]]; then
        OPTIONS="$OPTIONS --dbtype $DB_TYPE"
    fi

    if [[ ! -z $DB_SINGLE ]] && [[ $DB_SINGLE -eq 1 ]]; then
        OPTIONS="$OPTIONS --db.single"
    fi

    if [[ ! -z $DB_DYNAMO_TABLENAME ]] && [[ $DB_DYNAMO_TABLENAME != "" ]]; then
        OPTIONS="$OPTIONS --db.dynamo.tablename $DB_DYNAMO_TABLENAME"
    fi

    if [[ ! -z $DB_DYNAMO_READONLY ]] && [[ $DB_DYNAMO_READONLY -eq 1 ]]; then
        OPTIONS="$OPTIONS --db.dynamo.read-only"
    fi

    if [[ ! -z $GCMODE ]] && [[ $GCMODE != "" ]]; then
        OPTIONS="$OPTIONS --gcmode $GCMODE"
    fi

    if [[ ! -z $STATE_TRIE_CACHE_LIMIT ]] && [[ $STATE_TRIE_CACHE_LIMIT != "" ]]; then
        OPTIONS="$OPTIONS --state.trie-cache-limit $STATE_TRIE_CACHE_LIMIT"
    fi

    if [[ ! -z $STATEDB_CACHE_TYPE ]] && [[ $STATEDB_CACHE_TYPE != "" ]]; then
        OPTIONS="$OPTIONS --statedb.cache.type $STATEDB_CACHE_TYPE"
        if [[ ! -z $STATEDB_REDIS_ENDPOINT ]] && [[ $STATEDB_REDIS_ENDPOINT != "" ]]; then
            OPTIONS="$OPTIONS --statedb.cache.redis.endpoints $STATEDB_REDIS_ENDPOINT"
        fi

        if [[ ! -z $STATEDB_REDIS_PUBLISH ]] && [[ $STATEDB_REDIS_PUBLISH -eq 1 ]]; then
            OPTIONS="$OPTIONS --statedb.cache.redis.publish"
        fi

        if [[ ! -z $STATEDB_REDIS_SUBSCRIBE ]] && [[ $STATEDB_REDIS_SUBSCRIBE -eq 1 ]]; then
            OPTIONS="$OPTIONS --statedb.cache.redis.subscribe"
        fi
    fi

    if [[ ! -z $VM_INTERNALTX ]] && [[ $VM_INTERNALTX -eq 1 ]]; then
        OPTIONS="$OPTIONS --vm.internaltx"
    fi

    if [[ ! -z $KES_NODETYPE_SERVICE_ENABLE ]] && [[ $KES_NODETYPE_SERVICE_ENABLE -eq 1 ]]; then
        OPTIONS="$OPTIONS --kes.nodetype.service"
    fi
}

start() {
    __pid_run
    [ -n "$pid" ] && echo "kend already running...[$pid]" && return

    echo -n "Starting kend: "

    __check_option

    BASEDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
    CURRENTFILE=`basename "$0"`
    OPTIONS="$OPTIONS --autorestart.daemon.path $BASEDIR/$CURRENTFILE"

    $BIN/ken $OPTIONS >> ${LOG_DIR}/kend.out 2>&1 &
    RETVAL=$?
    PIDNUM=$!
    set +f
    if [ $RETVAL = 0 ]; then
        echo $PIDNUM > ${pidfile}
        echo "OK"
    else
        echo "Fail"
    fi
    return $RETVAL
}

start_docker() {
    echo -n "Starting kend: "
    __check_option

    echo "$BIN/ken $OPTIONS"
    $BIN/ken $OPTIONS
}

stop() {
    __pid_run
    [ -z "$pid" ] && echo "kend is not running" && return
    echo -n "Shutting down kend: "
    __kill_timeout $(eval "cat ${pidfile}") && rm -f ${pidfile}
}

status() {
    __pid_run
    if [ -n "$pid" ]; then
        echo "kend is running"
    else
        echo "kend is down"
    fi
}

restart() {
    stop
    sleep 3
    start
}

case "$1" in
    start)
        start
        ;;
    start-docker)
        start_docker
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    restart)
        restart
        ;;
    *)
        echo "Usages: kend {start|start-docker|stop|restart|status}"
        exit 1
        ;;
esac
exit 0
[ec2-user@ip-172-31-8-35 bin]$

