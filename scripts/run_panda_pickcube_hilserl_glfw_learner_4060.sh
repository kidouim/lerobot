#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_PATH="$REPO_ROOT/configs/train_panda_pickcube_hilserl_glfw_train_keyboard.json"
RUN_ID="${1:-panda_pickcube_glfw_$(date +%m%d_%H%M%S)}"
OUTPUT_DIR="$REPO_ROOT/outputs/$RUN_ID/learner"
PYTHON_BIN="$HOME/miniconda3/envs/lerobot-hil/bin/python"
LEARNER_PORT=50051

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
export MUJOCO_GL=glfw
export LEROBOT_HILSERL_PROFILE=0
export LEROBOT_GYM_HIL_USE_VIEWER="${LEROBOT_GYM_HIL_USE_VIEWER:-0}"
export LEROBOT_GYM_HIL_RENDER_MODE=rgb_array
export LEROBOT_GYM_HIL_RESET_DELAY_SECONDS=0

echo "[LEARNER] config_path=$CONFIG_PATH"
echo "[LEARNER] output_dir=$OUTPUT_DIR"
echo "[LEARNER] MUJOCO_GL=$MUJOCO_GL viewer=$LEROBOT_GYM_HIL_USE_VIEWER task=PandaPickCubeKeyboard-v0 fps=10 online_steps=2000"
nvidia-smi || true
ss -ltnp | grep ":${LEARNER_PORT}" || true

exec "$PYTHON_BIN" -m lerobot.rl.learner --config_path "$CONFIG_PATH" --output_dir "$OUTPUT_DIR"
