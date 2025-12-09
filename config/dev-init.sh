#####################################################################
# Invoke this script from your shell login script (e.g. .profile) as follows:
# # Dev environment set up
# . ~/work/dev/projects/etc/dev-setup/dev-init.sh

if [ -z ${SPM_WORK_HOME+x} ]; then echo "Warning: SPM_WORK_HOME is unset";  fi

export APPS_HOME=$SPM_WORK_HOME/apps
export LIBS_HOME=$SPM_WORK_HOME/lib


#####################################################################
# Set active view
#

export VIEW_ROOT=$SPM_WORK_HOME/dev

export PROJ=$VIEW_ROOT/projects
export PROJ_SITE=$VIEW_ROOT/projects-site
export PROJ_CP=$VIEW_ROOT/projects-cp

alias proj="cd $PROJ"
alias proj-site="cd $PROJ_SITE"
alias proj-cp="cd $PROJ_CP"
alias to="cd $VIEW_ROOT/build/testoutput"


#####################################################################
# Set up toolchain
#

# Mysql
#MYSQL_BIN=/usr/local/mysql/bin
#MYSQL_BIN=$APPS_HOME/mysql-8.0.30-macos12-x86_64/bin
MYSQL_BIN=/Users/Shared/DBngin/mysql/8.0.27/bin
export PATH=$PATH:$MYSQL_BIN

# Docker
RANCHER_BIN=$HOME/.rd/bin
export PATH=$PATH:$RANCHER_BIN

# Java
if [ -f /usr/libexec/java_home ]; then
  export JAVA_HOME=`/usr/libexec/java_home -v 17`
  export PATH=$JAVA_HOME/bin:$PATH
fi

# Ant
if [ -d $APPS_HOME/apache-ant-1.9.2 ]; then
  export ANT_HOME=$APPS_HOME/apache-ant-1.9.2
  export PATH=$PATH:$ANT_HOME/bin
fi

# Gradle
if [ -d $APPS_HOME/gradle-7.6 ]; then
  export GRADLE_HOME=$APPS_HOME/gradle-7.6
  export PATH=$PATH:$GRADLE_HOME/bin
fi

# Diff tool for comparing files/directories
if [ "$(uname)" = "Darwin" ]; then
  export PATH=$PATH:/Applications/Meld.app/Contents/MacOS
  export DIFF_TOOL=Meld
fi

if command -v meld &>/dev/null
then
  export DIFF_TOOL=meld
elif command -v Meld &>/dev/null
then
  export DIFF_TOOL=Meld
else
  export DIFF_TOOL="diff --brief -r"
fi

# Set tool options
export GRADLE_OPTS="-Xmx3072m"
export MAVEN_OPTS="-Xmx712M -XX:MaxPermSize=512M"

# Lightweight editor as referenced by "open" command on MacOS
export DEV_EDITOR="Visual Studio Code"

# Stripe CLI
export STRIPE_CLI_HOME=$LIBS_HOME/stripe-java-17.15.0/stripe-cli-1.3.5


#####################################################################
# Set up aliases
#

alias ls='ls -F'
alias ll='ls -la'
alias lr='ls -latr'

alias ports='lsof -Pn | grep LISTEN'

alias sshproxy='ssh -F ~/.ssh/config-proxy'
alias sshdirect='ssh'

alias db='mysql -u root -ppastprod -P3306 --protocol=tcp'
alias start-db='sudo launchctl load -w /Library/LaunchDaemons/com.mysql.mysql.plist'
alias stop-db='sudo launchctl unload -w /Library/LaunchDaemons/com.mysql.mysql.plist'

alias diff-tests='$DIFF_TOOL $PROJ/tn-tests/src/main/resources $VIEW_ROOT/build/testoutput >/dev/null 2>&1 &'
alias diff-create-schema='$DIFF_TOOL $PROJ/tn-tests/src/main/resources/tn/schema/tn/SchemaManagerTestPostCreateMySQL.txt  $VIEW_ROOT/build/testoutput/tn/schema/tn/SchemaManagerTestPostCreateMySQL.txt  >/dev/null 2>&1 &'
alias diff-upgrade-schema='$DIFF_TOOL $VIEW_ROOT/build/testoutput/tn/schema/tn/upgradedStructure.txt  $VIEW_ROOT/build/testoutput/tn/schema/tn/testStructure.txt  >/dev/null 2>&1 &'

alias edit='open -a "${DEV_EDITOR}"'
alias latestTag='git tag -n --sort=creatordate | tail -1'

alias app-server-logs='proj; gradle copyAppServerInstance; edit $PROJ/../build/app-server-spm-instance'
alias stripe=$STRIPE_CLI_HOME/stripe

# Aliases for projects-cp
alias cp-prod="echo '********* WARNING: MODIFYING PRODUCTION *********'; CP_ENV=$HOME/.do/prod "
alias cp-test="CP_ENV=$PROJ_CP/config/test-cp-env PROJECTS_CP_WORK_DIR=$VIEW_ROOT/build-cp/work"


#####################################################################
# Configure shell
#

# Provide a higher file descriptor limit - the default is 256
ulimit -n 8000
