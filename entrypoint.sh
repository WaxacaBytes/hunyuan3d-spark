#!/bin/bash
set -e

echo "[hunyuan3d-spark] Starting Hunyuan3D 2.1..."

# Force pip-installed cuBLAS 13.1+ over the system CUDA toolkit's 13.0.2, which
# lacks Blackwell (sm_121 / compute 12.1) support.  LD_PRELOAD is required
# because the NVIDIA container runtime injects the system libs early in the
# search path, bypassing both LD_LIBRARY_PATH and torch's RPATH.
CUBLAS_DIR="/opt/py310/lib/python3.10/site-packages/nvidia/cu13/lib"
if [ -d "$CUBLAS_DIR" ]; then
    export LD_PRELOAD="${CUBLAS_DIR}/libcublas.so.13:${CUBLAS_DIR}/libcublasLt.so.13${LD_PRELOAD:+:$LD_PRELOAD}"
    echo "[hunyuan3d-spark] cuBLAS override applied from pip package"
fi

cd /workspace/Hunyuan3D-2.1

# Download ESRGAN weights if not present
if [ ! -f "hy3dpaint/ckpt/RealESRGAN_x4plus.pth" ]; then
    echo "[hunyuan3d-spark] Downloading ESRGAN weights..."
    mkdir -p hy3dpaint/ckpt
    wget -q --show-progress \
        https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth \
        -P hy3dpaint/ckpt \
        || echo "[hunyuan3d-spark] Warning: ESRGAN download failed, continuing without it"
else
    echo "[hunyuan3d-spark] ESRGAN weights already present."
fi

# Models (DIT, VAE, paint) auto-download from HuggingFace on first inference.
# HF cache is persisted via the hunyuan3d-cache volume mount.

echo "[hunyuan3d-spark] Launching Gradio UI on port 7860..."
exec python gradio_app.py --host 0.0.0.0 --port 7860
