## My little library for maniplulating configuration files
## created by https://github.com/peedy2495

# replace variablename found in a file with it's content;
# ReplVar [varname] [filepath]
ReplVar() {
    content=$(eval "echo \${${1}}")
    sed -i "s/$1/$content/g" $2
}

# Insert text into a file before found match;
# PlaceBefore [matchstring] [content] [filepath]
PlaceBefore() {
    sed -i "/$1/i$2" $3
}

# Insert text into a file after found match;
# PlaceAfter [matchstring] [content] [filepath]
PlaceAfter() {
    sed -i "/$1/a$2" $3
}

# Disable (comment) all matched keys in file;
# KeyDisable [key] [filepath]
KeyDisable() {
    sed -i "/$1/s/^/#/g" $2
}

# Enable (comment out) all matched keys in file;
# KeyEnable [key] [filepath]
KeyEnable() {
    sed -i "/$1/s/^#//g" $2
}

# Set value of a key separated with '=' within a configfile;
# KeySet [key] [value] [filepath]
KeySet() {
    KeyEnable $1 $3
    sed -i "/^$1/s/\(.[^=]*\)\([ \t]*=[ \t]*\)\(.[^=]*\)/\1\2$2/" $3
}