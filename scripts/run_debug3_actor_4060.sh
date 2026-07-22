#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="$REPO_ROOT/configs/train_panda_pickcube_hilserl_debug3_keyboard.json"
RUN_ID="${1:-}"
PYTHON_BIN="$HOME/miniconda3/envs/lerobot-hil/bin/python"
LEARNER_ADDRESS=127.0.0.1:50051

if [[ -z "$RUN_ID" ]]; then
    echo "Usage: $0 <run-id>"
    echo "Use the RUN_ID printed by scripts/run_debug3_learner_4060.sh."
    exit 2
fi

if ! ss -ltnH | awk '{print $4}' | grep -Eq ':50051$'; then
    echo "[ACTOR] Learner is not running yet at $LEARNER_ADDRESS."
    echo "[ACTOR] Start scripts/run_debug3_learner_4060.sh $RUN_ID first, then wait for its gRPC startup log."
    echo "[ACTOR] Current port status:"
    ss -ltnp | grep ':50051' || true
    exit 1
fi

source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate lerobot-hil
export CUDA_VISIBLE_DEVICES=0
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

OUTPUT_DIR="$REPO_ROOT/outputs/$RUN_ID/actor_$(date +%m%d_%H%M%S)"
echo "[ACTOR] RUN_ID=$RUN_ID"
echo "[ACTOR] output_dir=$OUTPUT_DIR"
echo "[ACTOR] CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"
nvidia-smi || true
echo "[ACTOR] Port status before start:"
ss -ltnp | grep ':50051' || true

cmd=(
    "$PYTHON_BIN" -m lerobot.rl.actor
    --config_path "$CONFIG_PATH"
    --output_dir "$OUTPUT_DIR"
)
printf '[ACTOR] Command:'
printf ' %q' "${cmd[@]}"
printf '\n'
exec "${cmd[@]}"
