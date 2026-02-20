FROM abelpc/hunyuan3d-spark:base

ARG HUNYUAN3D_REPO=https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1.git
ARG HUNYUAN3D_REF=main

# Clone official Hunyuan3D-2.1 repo
RUN git clone "$HUNYUAN3D_REPO" /workspace/Hunyuan3D-2.1 && \
    cd /workspace/Hunyuan3D-2.1 && git checkout "$HUNYUAN3D_REF"

WORKDIR /workspace/Hunyuan3D-2.1

# Use our curated requirements (aarch64 + Python 3.10 compatible)
# instead of upstream's which pulls packages without aarch64 wheels
COPY requirements.txt /workspace/requirements-spark.txt
RUN pip install --no-cache-dir -r /workspace/requirements-spark.txt

# CUDA extensions (custom_rasterizer, DifferentiableRenderer, xatlas) are
# built at first run by entrypoint.sh on real aarch64 hardware — they
# require native compilation and fail under QEMU emulation in CI.

RUN mkdir -p output

EXPOSE 7860

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
