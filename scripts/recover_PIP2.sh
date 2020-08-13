

if [ $# -gt 3 ]
then
    NETLIST_DIR=$1
    ORIGINAL_NETLIST_FILE=$2
    ORIGINAL_NETLIST_NAME="$(basename "$ORIGINAL_NETLIST_FILE" .v)"
    TIME_LIMIT=$3
    MAX_WORDS=$4
    LIBRARY_DIR="lib"
    LIBRARY_NAME="harp.rlb"
    FULL_LIB_PATH=$LIBRARY_DIR/$LIBRARY_NAME
    if [ $# -gt 4 ]
    then
        FULL_LIB_PATH=$5
    fi
else
    echo "### Script usage Usage ###"
    echo "$ bash "$0" <netlist_dir> <netlist_name> <time_limit> <max_words> [library_file]"
    echo "Example run would be"
    echo "$ bash scripts/recover_PIP2.sh netlist/des3_v3_8to6 obf_debug_final.v 10s 10"
    echo "In practice it is a good idea to let the timelimit be around 4 to 5 hours"
    TIME_LIMIT="1s"
    MAX_WORDS="1000"
    NETLIST_DIR="netlist/des3_v3_8to6"
    ORIGINAL_NETLIST_NAME="obf_debug_final"
    ORIGINAL_NETLIST_FILE=$ORIGINAL_NETLIST_NAME".v"
    LIBRARY_DIR="lib"
    LIBRARY_NAME="harp.rlb"
    FULL_LIB_PATH=$LIBRARY_DIR/$LIBRARY_NAME
fi

BIN_DIR="bin"


# Does not need to be modified
LOG_FILE=$NETLIST_DIR/log.out
UPDATED_NETLIST_NAME=$ORIGINAL_NETLIST_NAME"_2"
UPDATED_NETLIST_FILE=$UPDATED_NETLIST_NAME".v"

# Get the current directory in case we need to return
curDir=$(pwd)
echo Working on $ORIGINAL_NETLIST_FILE

# Only use this if you have a lot of memory at your disposal
S_DOM=""
# S_DOM=" --S_DOM"

# The arguments for the max number of words
MAX_WORD_ARGUMENT="-max "$MAX_WORDS

echo ""
echo Generating the new Netlist...
java -jar $BIN_DIR/modify_netlist.jar $NETLIST_DIR/$ORIGINAL_NETLIST_FILE
echo New netlist created!

echo ""
echo Generating register dependency...
./$BIN_DIR/redpen --lib $FULL_LIB_PATH --net $NETLIST_DIR/$UPDATED_NETLIST_FILE > $NETLIST_DIR/reg_dep.txt
echo register dependency created at $NETLIST_DIR/reg_dep.txt!

echo ""
echo Generating cliques...
java -jar $BIN_DIR/clique.jar $NETLIST_DIR/$UPDATED_NETLIST_FILE $NETLIST_DIR/reg_dep.txt $MAX_WORD_ARGUMENT > $LOG_FILE
echo Cliques generated!

echo ""
echo Generating fsms...
echo Note this is run with timeout so using Ctrl+c will not stop the process
ERR_FILE_NAME="$(basename "$LOG_FILE" .out).err"
echo Error writen to $ERR_FILE_NAME
(timeout -s SIGKILL $TIME_LIMIT ./$BIN_DIR/m_refsm --lib $FULL_LIB_PATH --net $NETLIST_DIR/$UPDATED_NETLIST_FILE --word $NETLIST_DIR/fsms/all_ws.out --norst --tlimit 50000 $S_DOM >> $LOG_FILE) 2> $ERR_FILE_NAME
if [ $? -ne 0 ]
then
    echo "process crashed >_< (probably because of timeout)"
else
    echo multi refsm was successful, protection is probably not strong enough
fi
echo Original FSMs generated.

# This allows for a fine grain analysis of how each FSMs FF Group size can affect the total runtime
for file in $NETLIST_DIR/fsms/*[0-9].out; do 
    echo ""
    echo Reading from $file
    NEW_FILE_NAME=$NETLIST_DIR/fsms/"$(basename "$file" .out)_log.out"
    ERR_FILE_NAME=$NETLIST_DIR/fsms/"$(basename "$file" .out)_log.err"
    echo Writing to $NEW_FILE_NAME
    echo Error written to  $ERR_FILE_NAME
    echo Note this is run with timeout so using Ctrl+c will not stop the process
    (timeout -s SIGKILL $TIME_LIMIT ./$BIN_DIR/m_refsm --lib $FULL_LIB_PATH --net $NETLIST_DIR/$UPDATED_NETLIST_FILE --word $file --norst --tlimit 50000 $S_DOM > $NEW_FILE_NAME) 2> $ERR_FILE_NAME
    if [ $? -ne 0 ]
    then
        echo "process crashed (probably because of timeout)"
    else
        echo multi refsm successfully finished on the partial fsm group
    fi
done

# Return to the original directory at the end
cd $curDir