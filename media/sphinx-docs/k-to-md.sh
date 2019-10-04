#!/bin/sh
set -x

cp -f config.k config.md
cp -f beacon-chain.k beacon-chain.md
cp -f constants-mainnet.k constants-mainnet.md
cp -f constants-minimal.k constants-minimal.md
cp -f hash-tree.k hash-tree.md
cp -f types.k types.md

extract_python() {
  # Matches multi-line comment beginning with def ...(
  sed -i 's/^\/\*\s*def \([a-zA-Z_]*\)(\(.*\)/\n```\n\n#### `\1`\n\nPython reference:\n```python\ndef \1(\2/g' $FILE
  sed -i '/\/\*\s*$/{
        N
        s/\/\*\s*\n\s*def \([a-zA-Z_]*\)(\(.*\)/\n```\n\n#### `\1`\n\nPython reference:\n```python\ndef \1(\2/g
  }' $1

  # Matches multi-line comment beginning with class ...(
  sed -i 's/^\/\*\s*class \([a-zA-Z_]*\)(\(.*\)/\n```\n\n#### `\1`\n\nPython reference:\n```python\nclass \1(\2/g' $FILE
  sed -i '/\/\*\s*$/{
        N
        s/\/\*\s*\n\s*class \([a-zA-Z_]*\)(\(.*\)/\n```\n\n#### `\1`\n\nPython reference:\n```python\nclass \1(\2/g
  }' $1

  # Matches remaining multi-line comments
  sed -i 's/^\s*\/\*\(.*\)/\n```\n\nPython reference:\n```python\n\1/g' $1

  # End multi-line comment by switching to K mode
  sed -i 's/^\(.*\)\*\/\s*$/\1\n```\n\nK semantics:\n```k\n/g' $1

}

insert_title() {
  TITLE_PRE='1s/^\(.*\)/'
  TITLE_MID='\n============\n'
  TITLE_POST='\1/'

  sed -i "$TITLE_PRE$1$TITLE_MID$2$TITLE_POST" $3
}

title_no_k() {
  insert_title "$1" '' "$2"
}

title() {
  insert_title "$1" '\n```k\n' "$2"
}

enter_next_k() {
  sed -i '1s/^\s*\*\//\n```\n\nK semantics:\n```k\n/g' $1
}

enter_next_python() {
  sed -i '1s/^\s*\/\*\(.*\)/Python reference:\n```python\n\1/g' $FILE
}

FILE=beacon-chain.md
title_no_k "Beacon Chain" $FILE
sed -i '0,/^\s*\/\*/ s/^ *\/\*/\n\n/g' $FILE
sed -i '0,/^\s*\*\// s/^ *\*\//\n\n```k\n/g' $FILE
sed -i '0,/^\s*\*/ s/^ *\*\(.*\)/\1/g' $FILE
sed -i '0,/^\s*\*/ s/^ *\*\(.*\)/\1/g' $FILE

enter_next_python $FILE
enter_next_k $FILE

extract_python $FILE

echo '```' >> $FILE

FILE=hash-tree.md
title 'Hash Tree' $FILE

enter_next_python $FILE
enter_next_k $FILE

extract_python $FILE

echo '```' >> $FILE

FILE=config.md
title 'Configuration' $FILE

enter_next_k $FILE

extract_python $FILE

echo '```' >> $FILE

FILE=types.md
title 'Types' $FILE

enter_next_k $FILE

extract_python $FILE

echo '```' >> $FILE

FILE=constants-mainnet.md
title 'Constants (Mainnet)' $FILE
echo '```' >> $FILE

FILE=constants-minimal.md
title 'Constants (Minimal)' $FILE
echo '```' >> $FILE

