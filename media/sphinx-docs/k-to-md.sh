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

  # Matches multi-line comment beginning with def ...(
  sed -i 's/^\/\*\s*class \([a-zA-Z_]*\)(\(.*\)/\n```\n\n#### `\1`\n\nPython reference:\n```python\nclass \1(\2/g' $FILE
  sed -i '/\/\*\s*$/{
        N
        s/\/\*\s*\n\s*class \([a-zA-Z_]*\)(\(.*\)/\n```\n\n#### `\1`\n\nPython reference:\n```python\nclass \1(\2/g
  }' $1

  # Matches remaining multi-line comments
  sed -i 's/^\s*\/\*\(.*\)/\n```\n\nPython reference:\n```python\n\1/g' $1

  # End multi-line comment by switching to K mode
  sed -i 's/^\(.*\)\*\/\s*/\1\n```\n\nK semantics:\n```k/g' $FILE

}

FILE=beacon-chain.md
sed -i '1s/^\(.*\)/Beacon Chain\n============\n\1/' $FILE
sed -i '0,/^\s*\/\*/ s/^ *\/\*/\n\n/g' $FILE
sed -i '0,/^\s*\*\// s/^ *\*\//\n\n```k\n/g' $FILE
sed -i '0,/^\s*\*/ s/^ *\*\(.*\)/\1/g' $FILE
sed -i '0,/^\s*\*/ s/^ *\*\(.*\)/\1/g' $FILE

sed -i '1s/^\s*\/\*\(.*\)/Python reference:\n```python\n\1/g' $FILE
sed -i '1s/^\s*\*\//\n```\n\nK semantics:\n```k/g' $FILE

extract_python $FILE

echo '```' >> $FILE

FILE=hash-tree.md
sed -i '1s/^\(.*\)/Hash Tree\n============\n\n```k\n\1/' $FILE
sed -i '1s/^\s*\/\*\(.*\)/Python reference:\n```python\n\1/g' $FILE
sed -i '1s/^\s*\*\//\n```\n\nK semantics:\n```k/g' $FILE

extract_python $FILE

echo '```' >> $FILE

FILE=config.md
sed -i '1s/^\(.*\)/Configuration\n============\n\n```k\n\1/' $FILE
sed -i 's/^\s*\*\//\n```\n\nK semantics:\n```k/g' $FILE

extract_python $FILE

echo '```' >> $FILE

FILE=types.md
sed -i '1s/^\(.*\)/Types\n============\n\n```k\n\1/' $FILE
sed -i '1s/^\s*\*\//\n```\n\nK semantics:\n```k/g' $FILE

extract_python $FILE

echo '```' >> $FILE

FILE=constants-mainnet.md
sed -i '1s/^\(.*\)/Constants (Mainnet)\n============\n\n```k\1/' $FILE
echo '```' >> $FILE

FILE=constants-minimal.md
sed -i '1s/^\(.*\)/Constants (Minimal)\n============\n\n```k\1/' $FILE
echo '```' >> $FILE

