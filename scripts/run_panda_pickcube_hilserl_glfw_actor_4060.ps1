param(
    [Parameter(Mandatory = $true)]
    [string]$RunId,
    [switch]$Viewer
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$ConfigPath = Join-Path $RepoRoot "configs\train_panda_pickcube_hilserl_glfw_train_keyboard.json"
$OutputDir = Join-Path $RepoRoot "outputs\$RunId\actor_$(Get-Date -Format 'MMdd_HHmmss')"
$Python = Join-Path $env:USERPROFILE ".conda\envs\lerobot-hil-win\python.exe"
$Port = 50051

if (!(Test-Path $Python)) {
    throw "Python environment not found: $Python"
}
if (!(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)) {
    throw "Learner is not listening on 127.0.0.1:$Port. Start the learner first."
}

$env:CUDA_VISIBLE_DEVICES = "0"
$env:PYTORCH_CUDA_ALLOC_CONF = "expandable_segments:True"
$env:MUJOCO_GL = "glfw"
$env:LEROBOT_HILSERL_PROFILE = "0"
$env:LEROBOT_GYM_HIL_USE_VIEWER = if ($Viewer) { "1" } else { "0" }
$env:LEROBOT_GYM_HIL_RENDER_MODE = "rgb_array"
$env:LEROBOT_GYM_HIL_RESET_DELAY_SECONDS = "0"

Write-Host "[ACTOR] config_path=$ConfigPath"
Write-Host "[ACTOR] output_dir=$OutputDir"
Write-Host "[ACTOR] MUJOCO_GL=$env:MUJOCO_GL viewer=$env:LEROBOT_GYM_HIL_USE_VIEWER task=PandaPickCubeKeyboard-v0 fps=10 online_steps=2000"
nvidia-smi

& $Python -m lerobot.rl.actor --config_path $ConfigPath --output_dir $OutputDir
