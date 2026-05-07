ARG K_VERSION
FROM runtimeverificationinc/kframework-k:ubuntu-noble-${K_VERSION}

RUN    apt-get -y update             \
    && apt-get -y upgrade            \
    && apt-get -y install            \
         curl wget libssl-dev        \
         libsecp256k1-dev            \
         software-properties-common  \
         wabt                        \
    && apt-get -y clean              \
    && add-apt-repository ppa:ethereum/ethereum \
    && apt-get update                \
    && apt-get install solc

ARG USER_ID=9876
ARG GROUP_ID=9876
RUN    groupadd -g ${GROUP_ID} user \
    && useradd -m -u ${USER_ID} -s /bin/bash -g user user

USER user
WORKDIR /home/user

ENV PATH=/home/user/.local/bin:${PATH}

ARG UV_VERSION
RUN curl -LsSf https://astral.sh/uv/${UV_VERSION}/install.sh | sh \
 && uv --version

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain 1.95.0 -y

ENV PATH="/home/user/.cargo/bin:${PATH}"

RUN cargo install cargo-fuzz cargo-stylus wasm-opt

# Rust version used by the 9lives contract
RUN rustup install 1.85.0
RUN rustup target add wasm32-unknown-unknown --toolchain 1.85.0

RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/home/user/.foundry/bin:${PATH}"
RUN foundryup

ARG SKRIBE_DIST
COPY ${SKRIBE_DIST} .
RUN pip install --break-system-packages *.whl \
 && rm *.whl

RUN kdist --verbose build -j2 stylus-semantics.* \
 && skribe --help
