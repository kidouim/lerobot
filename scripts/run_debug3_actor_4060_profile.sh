#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="$REPO_ROOT/configs/train_panda_pickcube_hilserl_debug3_keyboard.json"
RUN_ID="${1:-}"
FPS="${2:-}"
STEPS="${3:-400}"
PUSH_SECONDS="${4:-4}"
PYTHON_BIN="$HOME/miniconda3/envs/lerobot-hil/bin/python"
LEARNER_ADDRESS=127.0.0.1:50051

if [[ -z "$RUN_ID" || -z "$FPS" ]]; then
    echo "Usage: $0 <run-id> <fps: 1|5|10> [steps: 400] [policy-push-seconds: 4]"
    exit 2
fi
if ! ss -ltnH | awk '{print $4}' | grep -Eq ':50051$'; then
    echo "[ACTOR] Learner is not running yet at $LEARNER_ADDRESS."
    echo "[ACTOR] Start run_debug3_learner_4060_profile.sh first."
    exit 1
fi

source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate lerobot-hil
export CUDA_VISIBLE_DEVICES=0
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export LEROBOT_HILSERL_PROFILE=1
export LEROBOT_GYM_HIL_USE_VIEWER=0
export LEROBOT_GYM_HIL_RENDER_MODE=rgb_array
export LEROBOT_GYM_HIL_RESET_DELAY_SECONDS=0

OUTPUT_DIR="$REPO_ROOT/outputs/$RUN_ID/actor_$(date +%m%d_%H%M%S)"
echo "[ACTOR] config_path=$CONFIG_PATH"
echo "[ACTOR] output_dir=$OUTPUT_DIR"
echo "[ACTOR] task=PandaPickCubeKeyboard-v0 fps=$FPS max_steps=$STEPS"
echo "[ACTOR] profile overrides: viewer=off render_mode=rgb_array reset_delay_s=0 push_seconds=$PUSH_SECONDS"
nvidia-smi || true
ss -ltnp | grep ':50051' || true

cmd=(
    "$PYTHON_BIN" -m lerobot.rl.actor
    --config_path "$CONFIG_PATH"
    --output_dir "$OUTPUT_DIR"
    --env.fps "$FPS"
    --steps "$STEPS"
    --policy.online_steps "$STEPS"
    --policy.actor_learner_config.policy_parameters_push_frequency "$PUSH_SECONDS"
)
printf '[ACTOR] Command:'; printf ' %q' "${cmd[@]}"; printf '\n'
exec "${cmd[@]}"
