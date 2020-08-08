# FLOSS
This is the public repo releasing the binary of the FLOSS (Functional Logic Obfuscation Security Assessment Suite) framework.

# Requirements (Working Environment)
To run the jar files it is recommended that you have at least Java 1.8.

To use the bash script and run the m_refsm and redpen executables, it is recommended that you use a **linux operating system (ubuntu was used)**.

# Running
There are 4 steps provided in this repo that enables extraction of the FSMs

1. Insert q pins into FFs (modify_netlist.jar)
2. Extract register interaction (redpen)
3. Extract all possible Flip Flop Groups (clique.jar)
4. Extract all FSMs (m_refsm)

Unless you have a good understanding of the jobs of each tool it is a good idea to use the provided script. It can be run using the following command,
```
bash scripts/recover_PIP2.sh <netlist_dir> <netlist_name> <time_limit> <max_words> [library_file]
```

## Q Pin Insertion
Our tool uses the fact that an IC powers up into all logical 0s for the flip flops. The tool m_refsm (REFSM) does not have a distinction between Q and QN pins. REFSM has the ability to search for a reset state, but doing so is costly. It is ideal to give the tool Q pins and flagging REFSM with --norst when not looking for a reset state to ensure that the correct power on state is used.

The q pin insertion tool (modify_netlist.jar) reads in the netlist (given through the argument of the java command) and outputs a new version of the netlist as a file with a slightly modified name in the same location of the original netlist.

Run using the following command
```
java -jar bin/modify_netlsit.jar <netlist_file_name>
```
Note: that the input netlist file needs to be verilog!

## Register Interaction Extraction
The register interaction graph is used by the clique finding tool for more rapidly identifying cliques. It could have been included in the clique extraction tool, but the register interaction graph is needed for other workflows, and had already existed.

The register interaction graph extractor needs (for accuracy reasons) to know how the cell library works, which is why it needs an rlb file. We have been working on a verilog library file to rlb file converter recently, but there is no expected release date. To run the register interaction graph use the following command,
```
./bin/redpen --lib <library_file_name> --net <modified_netlist_file_name> --out <output_graph_name>
```

## Clique Extraction
The third step extracts all flip flop groups that form cliques. The current version will require a golden netlist as input that labels the OFSM/DFSM. The reason being that the maximum and minimum number of flip flops are not known by the tool. Future versions will allow the max and mins to be specified by options. To run the clique extractor use the following command,
```
java -jar clique <netlist> <register dependency> [Options]
```
The only option available is adjusting the maximum number of printed words in the files that are generated.

## FSM Extraction
The last part of the current workflow for extracting FSMs is the new multi-REFSM tool which extracts multiple FSMs from the same netlist in the order they are given. The command used for multi-REFSM is the following,
```
./bin/m_refsm --lib <library_file_name> --net <modified_netlist_file_name> --word <word_file> [Options]
```
There are a lot of options for the m_refsm tool. Perhaps the best are the --norst and the --tlimit. The --norst flag will prevent multi-REFSM from looking for the reset signal. The --tlimit flag requires a number following it and will force multi-REFSM to kick out of state exploration for an individual FSM once a fixed number of transitions are found. If multi-REFSM kicks out using the --tlimit heuristics, a message will be printed to standard output (or the specified file if --out is used to redirect output to a file).

