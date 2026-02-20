FROM abelpc/hunyuan3d-spark:base

ARG HUNYUAN3D_REPO=https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1.git
ARG HUNYUAN3D_REF=main

# Clone official Hunyuan3D-2.1 repo
RUN git clone "$HUNYUAN3D_REPO" /workspace/Hunyuan3D-2.1 && \
    cd /workspace/Hunyuan3D-2.1 && git checkout "$HUNYUAN3D_REF"

WORKDIR /workspace/Hunyuan3D-2.1

# Install requirements (filtered for aarch64 + Python 3.10 base image)
# bpy is already built from source in the base image
# cupy / open3d / deepspeed don't have aarch64 wheels and aren't required
RUN sed -i '/^--extra-index-url/d; /^bpy/d; /^cupy/d; /^open3d/d; /^deepspeed/d' requirements.txt && \
    pip install --no-cache-dir -r requirements.txt

# Build CUDA extensions from source (Python 3.10, can't use pre-built cp312 wheels)
RUN cd hy3dpaint/custom_rasterizer && pip install -e . --no-build-isolation
RUN cd hy3dpaint/DifferentiableRenderer && bash compile_mesh_painter.sh

RUN mkdir -p output

EXPOSE 7860

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
