#!/bin/bash

cat <<EOF | tee .git/hooks/commit-msg
#!/bin/sh

conform enforce --commit-msg-file \$1
EOF
chmod +x .git/hooks/commit-msg
