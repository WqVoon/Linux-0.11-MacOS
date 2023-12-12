#!/bin/bash
#
# callgraph -- Generate a callgraph of a specified function in specified file/directory
#
# -- Based on cflow and tree2dotx
#
# Usage:
#
#       $ ./scripts/callgraph.sh
#
#           -f func_name
#           -d directory
#           -F filterstr
#           -D depth
#           -o directory
#
#
# Output: out/func.dir_file_name.svg
#

# OS
OS=$(uname)

# Tree2Dot
tree2dotx=./scripts/tree2dotx.sh

# Output directory
OUT_DIR=out
PIC_TYPE=svg

# Default setting

# Input: Function Name [Directory Name]
func=main
dir=./

# Default depth of the tree
depth=

# filterstr for tree2dotx
filterstr=""

# Usage

function usage
{
    echo ""
    echo "  $0 "
    echo ""
    echo "   -f func_name"
    echo "   -d directory|file"
    echo "   -F filterstr"
    echo "   -D depth"
    echo "   -o directory"
    echo "   -t output format type"
    echo ""
}

while getopts "F:f:d:D:o:t:h" opt;
do
    case $opt in
        F)
            filterstr=$OPTARG
        ;;
        f)
            func=$OPTARG
        ;;
        d)
            [ -n "$OPTARG" ] && [ -f "$OPTARG" -o -d "$OPTARG" ] && dir=$OPTARG
        ;;
        D)
            depth=$OPTARG
        ;;
        o)
            output=$OPTARG
            [ ! -d "$output" ] && mkdir -p $output
            OUT_DIR=$output
        ;;
        t)
            PIC_TYPE=$OPTARG
        ;;
        h|?)
            usage $0;
            exit 1;
        ;;
    esac
done

# Check the function and find out its file
if [ -d "$dir" ]; then
	match=`grep " [a-zA-Z0-9_]*${func}[a-zA-Z0-9_]*(.*)" -iur $dir | grep "\.[ch]:"`
	file=`echo "$match" | cut -d ':' -f1`
else
	match="$dir"`grep " [a-zA-Z0-9_]*${func}[a-zA-Z0-9_]*(.*)" -iur $dir`
	file="$dir"
fi
[ $? -ne 0 ] && echo "Note: No such function found: $func" && exit 1
echo "Func: $func"
[ -z "$file" ] && echo "Note: No file found for $func" && exit 1

# Let users choose the target files
fileno=`echo $file | tr -c -d ' ' | wc -c`
((fileno+=1))
if [ $fileno -ne 0 ]; then
	echo "Match: $fileno"
	echo "File:"
	echo "     0  All files under $dir"
	echo "$match" | cat -n
	files=($file)
	read -p "Select: 0 ~ $fileno ? " file_in
	if [ $file_in -ne 0 ]; then
        while [ $file_in -lt 1 -o $file_in -gt $fileno ]; do
		    read -p "Select: 1 ~ $fileno ? " file_in
	    done
	    ((file_in-=1))
	    file=${files[$file_in]}
	    ((file_in+=1))
    fi
else
	file_in=1
fi

if [ $file_in -ne 0 ]; then
    [ -z "$file" ] && echo "Note: No file found for $func" && exit 1
    echo "File: $file"
    func=`echo "$match" | sed -n -e "${file_in},${file_in}p" | sed -n -e "s/.* \([a-zA-Z0-9_]*${func}[a-zA-Z0-9_]*\)(.*).*/\1/p"`
    [ -z "$func" ] && echo "Note: No such function found: $func" && exit 1
else
    file="`find -L $dir -name '*.c' -or -name '*.h' | tr '\n' ' '`"
fi

# Genrate the calling tree of this function
# Convert it to .dot format with tree2dotx
# Convert it to jpg format with dot of Graphviz
if [ $file_in -ne 0 ]; then
    tmp=`echo $file | tr '/' '_' | tr '.' '_'`
else
    tmp="all"
fi
pic=${func}.${tmp}.${PIC_TYPE}
long_pic=${OUT_DIR}/${pic}

which cflow >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: cflow doesn't exist, please install it..."
    exit 1
else
    [ -n "$depth" ] && depth="-d $depth "
    calltree="cflow -b $depth -m"
fi

which dot >/dev/null 2>&1
[ $? -ne 0 ] && "Error: dot doesn't exist, please install graphviz..."

echo "Command: ${calltree} ${func} ${file} | ${tree2dotx} "${filterstr}" 2>/dev/null | dot -T${PIC_TYPE} -o $long_pic"
${calltree} ${func} ${file} | ${tree2dotx} -f "${filterstr}" 2>/dev/null | dot -T${PIC_TYPE} -o $long_pic

# Tell users
echo "Target: ${file}: ${func} -> ${long_pic}"

# Display it
display ${OUT_DIR}/${long_pic} >/dev/null 2>&1 &
