#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="$REPO_ROOT/configs/train_panda_pickcube_hilserl_glfw_train_keyboard.json"
RUN_ID="${1:?Usage: $0 <run-id from learner>}"
OUTPUT_DIR="$REPO_ROOT/outputs/$RUN_ID/actor_$(date +%m%d_%H%M%S)"
PYTHON_BIN="$HOME/miniconda3/envs/lerobot-hil/bin/python"
LEARNER_ADDRESS=127.0.0.1:50051

if ! ss -ltnH | awk '{print $4}' | grep -Eq ':50051$'; then
    echo "[ACTOR] Learner is not running yet at $LEARNER_ADDRESS."
    exit 1
fi

source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate lerobot-hil
export CUDA_VISIBLE_DEVICES=0
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
export MUJOCO_GL=glfw
export LEROBOT_HILSERL_PROFILE=0
export LEROBOT_GYM_HIL_USE_VIEWER="${LEROBOT_GYM_HIL_USE_VIEWER:-0}"
export LEROBOT_GYM_HIL_RENDER_MODE=rgb_array
export LEROBOT_GYM_HIL_RESET_DELAY_SECONDS=0

echo "[ACTOR] config_path=$CONFIG_PATH"
echo "[ACTOR] output_dir=$OUTPUT_DIR"
echo "[ACTOR] MUJOCO_GL=$MUJOCO_GL viewer=$LEROBOT_GYM_HIL_USE_VIEWER task=PandaPickCubeKeyboard-v0 fps=10 online_steps=2000"
nvidia-smi || true
ss -ltnp | grep ':50051' || true

exec "$PYTHON_BIN" -m lerobot.rl.actor --config_path "$CONFIG_PATH" --output_dir "$OUTPUT_DIR"
