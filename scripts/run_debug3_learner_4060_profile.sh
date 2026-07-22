#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="$REPO_ROOT/configs/train_panda_pickcube_hilserl_debug3_keyboard.json"
RUN_ID="${1:-}"
FPS="${2:-}"
STEPS="${3:-400}"
PUSH_SECONDS="${4:-4}"
PYTHON_BIN="$HOME/miniconda3/envs/lerobot-hil/bin/python"
LEARNER_PORT=50051

if [[ -z "$RUN_ID" || -z "$FPS" ]]; then
    echo "Usage: $0 <run-id> <fps: 1|5|10> [steps: 400] [policy-push-seconds: 4]"
    exit 2
fi

OUTPUT_DIR="$REPO_ROOT/outputs/$RUN_ID/learner"
if [[ -e "$OUTPUT_DIR" ]]; then
    echo "[LEARNER] Refusing to overwrite: $OUTPUT_DIR"
    exit 2
fi
if ss -ltnH | awk '{print $4}' | grep -Eq ":${LEARNER_PORT}$"; then
    echo "[LEARNER] Port ${LEARNER_PORT} is already in use."
    ss -ltnp | grep ":${LEARNER_PORT}" || true
    exit 2
fi

source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate lerobot-hil
export CUDA_VISIBLE_DEVICES=0
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export LEROBOT_HILSERL_PROFILE=1
export LEROBOT_GYM_HIL_USE_VIEWER=0
export LEROBOT_GYM_HIL_RENDER_MODE=rgb_array
export LEROBOT_GYM_HIL_RESET_DELAY_SECONDS=0

echo "[LEARNER] config_path=$CONFIG_PATH"
echo "[LEARNER] output_dir=$OUTPUT_DIR"
echo "[LEARNER] task=PandaPickCubeKeyboard-v0 fps=$FPS max_steps=$STEPS"
echo "[LEARNER] profile overrides: viewer=off render_mode=rgb_array reset_delay_s=0 push_seconds=$PUSH_SECONDS"
nvidia-smi || true
ss -ltnp | grep ":${LEARNER_PORT}" || true

cmd=(
    "$PYTHON_BIN" -m lerobot.rl.learner
    --config_path "$CONFIG_PATH"
    --output_dir "$OUTPUT_DIR"
    --env.fps "$FPS"
    --steps "$STEPS"
    --policy.online_steps "$STEPS"
    --policy.actor_learner_config.policy_parameters_push_frequency "$PUSH_SECONDS"
)
printf '[LEARNER] Command:'; printf ' %q' "${cmd[@]}"; printf '\n'
echo "[LEARNER] Wait for '[LEARNER] gRPC server started', then run actor with the same arguments."
exec "${cmd[@]}"
