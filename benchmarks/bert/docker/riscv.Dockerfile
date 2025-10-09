FROM pourpourr/debian-base:trixie


RUN apt-get update && apt-get install -y pbzip2 pv bzip2 libcurl4 curl
RUN apt install -y python3-torch python3-onnx python3-onnxruntime python3-numpy  python3-pip
RUN pip install --user --break-system-packages grpcio transformers six setuptools tokenization --index-url https://gitlab.com/api/v4/projects/56254198/packages/pypi/simple

WORKDIR /workspace
# RUN . ~/py313-env/bin/activate
# RUN pip install setuptools
# Install third_party library
RUN mkdir /tmp/third_party \
    && cd /tmp/third_party \
    && git clone https://github.com/pybind/pybind11.git \
    && mv pybind11 pybind \
    && cd /tmp/third_party/pybind 
    # \ 
    # && git reset --hard 25abf7efba

# Install LoadGen
RUN cd /tmp/ \
    && git clone https://github.com/lrq619/loadgen.git \
    && cd /tmp/loadgen \
    && python3 setup.py install \
    && cd /tmp \
    && rm -rf /tmp/loadgen \
    && rm -rf /tmp/third_party