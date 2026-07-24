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

function get_latest_github_tag() {
  local owner="${1}"
  local repo="${2}"
  local remove_v="${3:-false}"
  local latest_tag
  latest_tag="$(curl -s "https://api.github.com/repos/${owner}/${repo}/releases/latest" | jq -r .tag_name)"
  if [[ "${remove_v}" == 'true' ]]; then
    echo -n "${latest_tag}" | tr -d 'v'
    return 0
  fi
  echo -n "${latest_tag}"
}

KERNEL="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(get_arch)"

echo "Install terraform-docs"
mkdir tf-docs-download
TF_DOCS_VERSION="$(get_latest_github_tag 'terraform-docs' 'terraform-docs' 'true')"
TFDOCS_URL="https://github.com/terraform-docs/terraform-docs/releases/download/v${TF_DOCS_VERSION}/terraform-docs-v${TF_DOCS_VERSION}-${KERNEL}-${ARCH}.tar.gz"
wget -qO- "${TFDOCS_URL}" | tar -C tf-docs-download -xzf -
cp tf-docs-download/terraform-docs /usr/local/bin

TFLINT_VERSION='0.63.1'
echo "Install tflint ${TFLINT_VERSION}"
TFLINT_URL="https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_${KERNEL}_${ARCH}.zip"
curl -sL "${TFLINT_URL}" -o /tmp/tflint.zip
unzip -d /usr/local/bin/ /tmp/tflint.zip
chmod +x /usr/local/bin/tflint
rm -f /tmp/tflint.zip
