#!/usr/bin/env sh
set -eu

# Resolve paths relative to this script so it can be run from any cwd.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
BOOTSTRAP_DIR="$ROOT_DIR/examples/state-bootstrap"
EXAMPLE_DIR="$ROOT_DIR/examples/cc-rubrik-poc-test"

# Defaults keep the command zero-config for AWS_PROFILE_NAME.
STATE_BUCKET="false"
BUCKET_NAME="cc-rubrik-poc-test-tfstate-opensearch"
PROFILE="AWS_PROFILE_NAME"
REGION="eu-west-2"
MIGRATE_STATE="false"
CREATE_BUCKET="false"

# Parse simple key/value style flags.
for arg in "$@"; do
  case "$arg" in
    state-bucket=true) STATE_BUCKET="true" ;;
    state-bucket=false) STATE_BUCKET="false" ;;
    bucket-name=*) BUCKET_NAME=${arg#*=} ;;
    profile=*) PROFILE=${arg#*=} ;;
    region=*) REGION=${arg#*=} ;;
    migrate-state=true) MIGRATE_STATE="true" ;;
    migrate-state=false) MIGRATE_STATE="false" ;;
    create-bucket=true) CREATE_BUCKET="true" ;;
    create-bucket=false) CREATE_BUCKET="false" ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: ./init-state.sh state-bucket=true|false [bucket-name=<name>] [profile=<aws-profile>] [region=<aws-region>] [migrate-state=true|false] [create-bucket=true|false]"
      exit 1
      ;;
  esac
done

if [ "$STATE_BUCKET" = "true" ]; then
  if [ "$CREATE_BUCKET" = "true" ]; then
    # 1) Create or reconcile the remote state bucket and guardrails.
    echo "Creating or reconciling remote state bucket using state-bootstrap..."
    terraform -chdir="$BOOTSTRAP_DIR" init
    terraform -chdir="$BOOTSTRAP_DIR" apply -auto-approve \
      -var="bucket_name=$BUCKET_NAME" \
      -var="aws_profile=$PROFILE" \
      -var="region=$REGION"
  else
    # Guardrail: default remote mode is non-mutating and requires an existing bucket.
    if ! aws s3api head-bucket --bucket "$BUCKET_NAME" --profile "$PROFILE" >/dev/null 2>&1; then
      echo "Remote state bucket does not exist or is not accessible: $BUCKET_NAME"
      echo "Create it first using one of these options:"
      echo "  1) ./examples/cc-rubrik-poc-test/init-state.sh state-bucket=true create-bucket=true bucket-name=$BUCKET_NAME profile=$PROFILE region=$REGION"
      echo "  2) terraform -chdir=examples/state-bootstrap apply -var='bucket_name=$BUCKET_NAME' -var='aws_profile=$PROFILE' -var='region=$REGION'"
      exit 1
    fi
  fi

  # 2) Generate a backend config file for this environment.
  BACKEND_FILE="$EXAMPLE_DIR/backend.hcl"
  cat > "$BACKEND_FILE" <<EOF
bucket       = "$BUCKET_NAME"
key          = "opensearch/example/terraform.tfstate"
region       = "$REGION"
profile      = "$PROFILE"
encrypt      = true
use_lockfile = true
EOF

  # 3) Initialize example with remote backend (optionally migrate local state).
  if [ "$MIGRATE_STATE" = "true" ]; then
    terraform -chdir="$EXAMPLE_DIR" init -migrate-state -reconfigure -backend-config=backend.hcl
  else
    terraform -chdir="$EXAMPLE_DIR" init -reconfigure -backend-config=backend.hcl
  fi

  echo "Remote state initialized with bucket: $BUCKET_NAME"
else
  # Local mode skips backend initialization and uses local state files.
  terraform -chdir="$EXAMPLE_DIR" init -backend=false
  echo "Initialized using local state."
fi
