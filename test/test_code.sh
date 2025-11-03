#!/usr/bin/env bash
# Code block and syntax highlighting tests for md2ansi Bash implementation
# This file is sourced by run_tests

test_section "Code Blocks and Syntax Highlighting"

# --------------------------------------------------------------------------------
# Fenced code blocks

input="\`\`\`
plain code
\`\`\`"

output=$(echo -e "$input" | ./md2ansi)
assert_contains "$output" "plain code" "Plain code block renders"
assert_contains "$output" "\`\`\`" "Code fence markers present"

# --------------------------------------------------------------------------------
# Python syntax highlighting

input="\`\`\`python
def hello():
    print('world')
\`\`\`"

output=$(echo -e "$input" | ./md2ansi)
assert_contains "$output" "def" "Python def keyword present"
assert_contains "$output" "hello" "Python function name present"
assert_contains "$output" "print" "Python print keyword present"

# --------------------------------------------------------------------------------
# JavaScript syntax highlighting

input="\`\`\`javascript
function test() {
    console.log('test');
}
\`\`\`"

output=$(echo -e "$input" | ./md2ansi)
assert_contains "$output" "function" "JavaScript function keyword present"
assert_contains "$output" "console" "JavaScript console present"

# --------------------------------------------------------------------------------
# Bash syntax highlighting

input="\`\`\`bash
if [ -f file ]; then
    echo 'exists'
fi
\`\`\`"

output=$(echo -e "$input" | ./md2ansi)
assert_contains "$output" "if" "Bash if keyword present"
assert_contains "$output" "then" "Bash then keyword present"
assert_contains "$output" "echo" "Bash echo command present"
assert_contains "$output" "fi" "Bash fi keyword present"

# --------------------------------------------------------------------------------
# Language aliases

input="\`\`\`py
def test():
    pass
\`\`\`"

output=$(echo -e "$input" | ./md2ansi)
assert_contains "$output" "def" "Python alias 'py' works"

input="\`\`\`js
const x = 1;
\`\`\`"

output=$(echo -e "$input" | ./md2ansi)
assert_contains "$output" "const" "JavaScript alias 'js' works"

input="\`\`\`sh
echo test
\`\`\`"

output=$(echo -e "$input" | ./md2ansi)
assert_contains "$output" "echo" "Bash alias 'sh' works"

# --------------------------------------------------------------------------------
# Comments highlighting

input="\`\`\`python
# This is a comment
code()
\`\`\`"

output=$(echo -e "$input" | ./md2ansi)
assert_contains "$output" "# This is a comment" "Python comment present"

input="\`\`\`javascript
// This is a comment
code();
\`\`\`"

output=$(echo -e "$input" | ./md2ansi)
assert_contains "$output" "// This is a comment" "JavaScript comment present"

input="\`\`\`bash
# Bash comment
echo test
\`\`\`"

output=$(echo -e "$input" | ./md2ansi)
assert_contains "$output" "# Bash comment" "Bash comment present"

# --------------------------------------------------------------------------------
# Tilde fences

input="~~~
code with tildes
~~~"

output=$(echo -e "$input" | ./md2ansi)
assert_contains "$output" "code with tildes" "Tilde fence works"

# --------------------------------------------------------------------------------
# Multiple code blocks

input="\`\`\`python
def first():
    pass
\`\`\`

\`\`\`python
def second():
    pass
\`\`\`"

output=$(echo -e "$input" | ./md2ansi)
assert_contains "$output" "first" "Multiple code blocks - first"
assert_contains "$output" "second" "Multiple code blocks - second"

# --------------------------------------------------------------------------------
# Syntax highlighting disable flag

input="\`\`\`python
def test():
    print('hello')
\`\`\`"

output=$(echo -e "$input" | ./md2ansi --no-syntax-highlight)
assert_contains "$output" "def test" "Code renders with --no-syntax-highlight"

# --------------------------------------------------------------------------------
# Mixed markdown and code

input="# Header

Some text

\`\`\`python
code()
\`\`\`

More text"

output=$(echo -e "$input" | ./md2ansi)
assert_contains "$output" "Header" "Mixed content - header"
assert_contains "$output" "Some text" "Mixed content - text before"
assert_contains "$output" "code()" "Mixed content - code block"
assert_contains "$output" "More text" "Mixed content - text after"

#fin
