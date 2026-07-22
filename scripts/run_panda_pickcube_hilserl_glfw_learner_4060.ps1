param(
    [string]$RunId = "panda_pickcube_glfw_$(Get-Date -Format 'MMdd_HHmmss')"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$ConfigPath = Join-Path $RepoRoot "configs\train_panda_pickcube_hilserl_glfw_train_keyboard.json"
$OutputDir = Join-Path $RepoRoot "outputs\$RunId\learner"
$Python = Join-Path $env:USERPROFILE ".conda\envs\lerobot-hil-win\python.exe"
$Port = 50051

if (!(Test-Path $Python)) {
    throw "Python environment not found: $Python"
}
if (Test-Path $OutputDir) {
    throw "Refusing to overwrite existing output directory: $OutputDir"
}
if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) {
    throw "Port $Port is already in use. Stop the previous learner first."
}

$env:CUDA_VISIBLE_DEVICES = "0"
$env:PYTORCH_CUDA_ALLOC_CONF = "expandable_segments:True"
$env:MUJOCO_GL = "glfw"
$env:LEROBOT_HILSERL_PROFILE = "0"
$env:LEROBOT_GYM_HIL_USE_VIEWER = "0"
$env:LEROBOT_GYM_HIL_RENDER_MODE = "rgb_array"
$env:LEROBOT_GYM_HIL_RESET_DELAY_SECONDS = "0"

Write-Host "[LEARNER] config_path=$ConfigPath"
Write-Host "[LEARNER] output_dir=$OutputDir"
Write-Host "[LEARNER] MUJOCO_GL=$env:MUJOCO_GL task=PandaPickCubeKeyboard-v0 fps=10 online_steps=2000"
nvidia-smi

& $Python -m lerobot.rl.learner --config_path $ConfigPath --output_dir $OutputDir
