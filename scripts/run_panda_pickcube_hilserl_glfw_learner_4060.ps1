param(
    [string]$RunId = "panda_pickcube_glfw_$(Get-Date -Format 'MMdd_HHmmss')",
    [switch]$Resume,
    [string]$HistoricalInterventionsPath
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
if (!$Resume -and (Test-Path $OutputDir)) {
    throw "Refusing to overwrite existing output directory: $OutputDir"
}
if ($Resume -and !(Test-Path (Join-Path $OutputDir "checkpoints\last"))) {
    throw "No checkpoint found for resume: $(Join-Path $OutputDir 'checkpoints\last')"
}
if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) {
    throw "Port $Port is already in use. Stop the previous learner first."
}

# TorchCodec on Windows requires the DLLs from a full shared FFmpeg build.
$ffmpegInstall = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like 'FFmpeg*' -and $_.InstallLocation } |
    Select-Object -First 1
if ($ffmpegInstall) {
    $ffmpegBin = Get-ChildItem -LiteralPath $ffmpegInstall.InstallLocation -Directory -Filter 'ffmpeg-*-full_build-shared' -ErrorAction SilentlyContinue |
        Select-Object -First 1 |
        ForEach-Object { Join-Path $_.FullName 'bin' }
    if ($ffmpegBin -and (Test-Path $ffmpegBin)) {
        $env:PATH = "$ffmpegBin;$env:PATH"
    }
}

$env:CUDA_VISIBLE_DEVICES = "0"
$env:LEROBOT_HILSERL_DISABLE_TORCH_COMPILE = "1"
$env:MUJOCO_GL = "glfw"
$env:LEROBOT_HILSERL_PROFILE = "0"
$env:LEROBOT_GYM_HIL_USE_VIEWER = "0"
$env:LEROBOT_GYM_HIL_RENDER_MODE = "rgb_array"
$env:LEROBOT_GYM_HIL_RESET_DELAY_SECONDS = "0"

Write-Host "[LEARNER] config_path=$ConfigPath"
Write-Host "[LEARNER] output_dir=$OutputDir"
Write-Host "[LEARNER] resume=$Resume historical_interventions=$HistoricalInterventionsPath"
Write-Host "[LEARNER] MUJOCO_GL=$env:MUJOCO_GL task=PandaPickCubeKeyboard-v0 fps=10 online_steps=2000"
nvidia-smi

$LearnerArgs = @("-m", "lerobot.rl.learner", "--config_path", $ConfigPath, "--output_dir", $OutputDir)
if ($Resume) {
    $LearnerArgs += "--resume=true"
}
if ($HistoricalInterventionsPath) {
    if (!(Test-Path $HistoricalInterventionsPath)) {
        throw "Historical intervention snapshot not found: $HistoricalInterventionsPath"
    }
    $LearnerArgs += "--historical_interventions_path=$HistoricalInterventionsPath"
}
& $Python @LearnerArgs
