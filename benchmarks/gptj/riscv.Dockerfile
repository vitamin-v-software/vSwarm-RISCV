FROM pourpourr/debian-base:trixie
# apt install -y python3-torch python3-numpy  python3-pip

# pip install --user --break-system-packages grpcio google protobuf accelerate grpcio-reflection transformers six setuptools pyyaml  --index-url https://gitlab.com/api/v4/projects/56254198/packages/pypi/simple

RUN apt-get update && apt-get install -y pbzip2 pv bzip2 libcurl4 curl build-essential cmake g++ git pkg-config \
    libboost-all-dev libssl-dev \
    libthrift-dev rapidjson-dev \
    ninja-build python3-dev \
    make \
    gcc \
    flex bison \
    libzstd-dev \
    liblz4-dev \
    libsnappy-dev \
    libbrotli-dev \
    libprotobuf-dev protobuf-compiler \
    python3-torch python3-numpy  python3-pip

RUN pip install --user --break-system-packages grpcio google protobuf accelerate grpcio-reflection transformers six setuptools pyyaml  --index-url https://gitlab.com/api/v4/projects/56254198/packages/pypi/simple


RUN mkdir /tmp/third_party \
    && cd /tmp/third_party \
    && git clone https://github.com/pybind/pybind11.git \
    && mv pybind11 pybind \
    && cd /tmp/third_party/pybind  
    # && git reset --hard 25abf7efba

# Install LoadGen
RUN cd /tmp/ \
    && git clone https://github.com/lrq619/loadgen.git \
    && cd /tmp/loadgen \
    && python3 setup.py install \
    && cd /tmp \
    && rm -rf /tmp/loadgen \
    && rm -rf /tmp/third_party

WORKDIR /resources