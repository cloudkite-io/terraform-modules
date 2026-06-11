#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

function retry_command() {
  # Source: https://github.com/aws-quickstart/quickstart-linux-utilities/blob/master/quickstart-cfn-tools.source#L413-L433
  # $1 = NumberOfRetries $2 = Command
  # retry_command 10 some_command.sh
  # Command will retry with linear back-off
  local -r __tries="${1}"; shift
  declare -a __run=("${@}")
  local -i __backoff_delay=2
  local __current_try=0
  until "${__run[@]}"
    do
      if (( __current_try == __tries ))
      then
        echo "Tried ${__current_try} times and failed!"
        return 1
      else
        echo "Retrying ...."
        sleep $(((__backoff_delay++) + (__current_try++)))
      fi
    done
}

function get_arch() {
  case "$(uname -m)" in
    armv5*) echo -n "armv5";;
    armv6*) echo -n "armv6";;
    armv7*) echo -n "armv7";;
    aarch64) echo -n "arm64";;
    arm64) echo -n "arm64";;
    x86) echo -n "386";;
    x86_64) echo -n "amd64";;
    i686) echo -n "386";;
    i386) echo -n "386";;
  esac
}


retry=5

echo "Install from brew"
## TODO: install all tools via binary releases instead of brew to avoid brew's flakiness on github actions runners
retry_command "${retry}" 'bash' '-c' 'brew install terraform terraform-docs'


KERNEL="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(get_arch)"

TFLINT_VERSION='0.63.1'
echo "Install tflint ${TFLINT_VERSION}"
TFLINT_URL="https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_${KERNEL}_${ARCH}.zip"
curl -sL "${TFLINT_URL}" -o /tmp/tflint.zip
unzip -d /usr/local/bin/ /tmp/tflint.zip
chmod +x /usr/local/bin/tflint
rm -f /tmp/tflint.zip
