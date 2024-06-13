#!/bin/bash

DEEPAAS_CLI_COMMAND="deepaas-cli predict "
args=$(cat "$INPUT_FILE_PATH")

# Function to decode the input parameters of the model if the execution is synchronous (input parameters are on the input variable)
decode_params_from_input(){
if echo "$args" | grep -q "input-files" ; then
files=$(echo "$args" | sed -e 's/{//g;!b' -e 's/}//g' -e 's/ //g' | awk -F"[\[\]]" '{print $2}' | sed -e 's/\[//g;!b' -e 's/\]//g' )

file_params=""
while IFS= read -r fp
do
        file_params="$file_params$fp "
done <<EOF
$(echo "$files" | awk -F '[,]' '{for (i=1; i<=NF; i++){print $i}}')
EOF
DEEPAAS_CLI_COMMAND="$DEEPAAS_CLI_COMMAND --files"
it=1
for file_param in $file_params
do
	case $it in 
	1) 	
	name=`echo $file_param | awk -F: '{print $2}' | sed -e 's/"//g'`
	it=$((it + 1))
	;;
	2) 	
	ext=`echo $file_param | awk -F: '{print $2}' | sed -e 's/"//g'`
	it=$((it + 1))
	;;
	3) 
	data=`echo $file_param | awk -F: '{print $2}' | sed -e 's/"//g'`
	it=1
	#decode base64 into file
	echo $data | base64 -d > $name.$ext
	DEEPAAS_CLI_COMMAND="$DEEPAAS_CLI_COMMAND $name.$ext"
	;;
	esac

done

params=""
while IFS= read -r p
do
        params="$params$p "
done <<EOF
$(echo "$args" | sed -e 's/{//g;!b' -e 's/}//g' -e 's/ //g' -e 's/,"oscar-files.*\]//g' | awk -F '[,]' '{for (i=1; i<=NF; i++){print $i}}')
EOF
else
params=""
while IFS= read -r p
do
        params="$params$p "
done <<EOF
$(echo "$args" | sed -e 's/{//g;!b' -e 's/}//g' -e 's/ //g' | awk -F '[,]' '{for (i=1; i<=NF; i++){print $i}}')
EOF

fi

for param in $params
do
key=$(echo $param | awk -F: '{print $1}' | sed -e 's/"//g' -e 's/^/--/g')
value=$(echo $param | awk -F: '{print $2}')
DEEPAAS_CLI_COMMAND="$DEEPAAS_CLI_COMMAND $key $value"
done

}

decode_params_from_input

OUTPUT_FILE="$TMP_OUTPUT_DIR/$IMAGE_NAME"

echo "[*] SCRIPT: Invoked > $DEEPAAS_CLI_COMMAND"
$(echo $DEEPAAS_CLI_COMMAND)