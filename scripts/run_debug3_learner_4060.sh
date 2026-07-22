#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="$REPO_ROOT/configs/train_panda_pickcube_hilserl_debug3_keyboard.json"
RUN_ID="${1:-}"
PYTHON_BIN="$HOME/miniconda3/envs/lerobot-hil/bin/python"
LEARNER_PORT=50051

if [[ -z "$RUN_ID" ]]; then
    echo "Usage: $0 <run-id>"
    echo "Example: $0 debug3_\$(date +%m%d_%H%M%S)"
    exit 2
fi

OUTPUT_DIR="$REPO_ROOT/outputs/$RUN_ID/learner"
if [[ -e "$OUTPUT_DIR" ]]; then
    echo "[LEARNER] Refusing to overwrite existing output directory: $OUTPUT_DIR"
    echo "[LEARNER] Choose a new run id for a fresh debug3 run."
    exit 2
fi

if ss -ltnH | awk '{print $4}' | grep -Eq ":${LEARNER_PORT}$"; then
    echo "[LEARNER] Port ${LEARNER_PORT} is already in use. Stop the existing learner first."
    ss -ltnp | grep ":${LEARNER_PORT}" || true
    exit 2
fi

source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate lerobot-hil
export CUDA_VISIBLE_DEVICES=0
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

echo "[LEARNER] RUN_ID=$RUN_ID"
echo "[LEARNER] output_dir=$OUTPUT_DIR"
echo "[LEARNER] CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"
nvidia-smi || true
echo "[LEARNER] Port status before start:"
ss -ltnp | grep ":${LEARNER_PORT}" || true

cmd=(
    "$PYTHON_BIN" -m lerobot.rl.learner
    --config_path "$CONFIG_PATH"
    --output_dir "$OUTPUT_DIR"
)
printf '[LEARNER] Command:'
printf ' %q' "${cmd[@]}"
printf '\n'
echo "[LEARNER] After '[LEARNER] gRPC server started', run: scripts/run_debug3_actor_4060.sh $RUN_ID"
exec "${cmd[@]}"
