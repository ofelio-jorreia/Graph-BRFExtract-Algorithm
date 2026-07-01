FROM nvidia/cuda:12.6.3-base-ubuntu24.04

# 1. Configurações de ambiente
ENV DEBIAN_FRONTEND=noninteractive

# 2. Instalação de dependências - TOTALMENTE COMPATÍVEL COM 24.04
RUN apt-get update && apt-get install -y --no-install-recommends \
    net-tools \
    iputils-ping \
    nano \
    curl \
    build-essential \
    lsb-release \
    wget \
    gnupg \
    ca-certificates \
    unzip \
    # Bibliotecas de compatibilidade para binários antigos (MPM/MATLAB)
    libcrypt1 \
    libncurses6 \
    # Dependências gráficas e de sistema (Nomes Noble Numbat)
    libasound2t64 \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcap2 \
    libcups2 \
    libdbus-1-3 \
    libfontconfig1 \
    libgbm1 \
    libgl1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libv4l-0 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxtst6 \
    libxt6 \
    zlib1g && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 3. Setup MPM (Use o comando anterior que agora deve encontrar as libs acima)
# 2. Setup MATLAB Package Manager (MPM) - CORREÇÃO DE SINTAXE
WORKDIR /tmp
RUN wget -q https://www.mathworks.com/mpm/glnxa64/mpm && \
    chmod +x mpm && \
    mkdir -p /usr/local/MATLAB/R2025a && \
    # Adicionado --input /dev/null para evitar que o MPM espere input do terminal
    ./mpm install \
        --release R2025a \
        --products MATLAB Image_Processing_Toolbox \
        --destinationFolder /usr/local/MATLAB/R2025a \
        --input /dev/null \
        --v && \
    rm mpm

# 4. Instalação de Python e VNC
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip \
    xvfb x11vnc fluxbox dbus-x11 && \
    rm -rf /var/lib/apt/lists/*

# Configurações de Ambiente
ENV PATH="/usr/local/MATLAB/R2025a/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/MATLAB/R2025a/bin/glnxa64:/usr/local/MATLAB/R2025a/sys/os/glnxa64:$LD_LIBRARY_PATH"
ENV PATH=/usr/local/cuda/bin:$PATH

WORKDIR /ofelio

# 5. Virtual Env e TensorFlow
RUN python3 -m venv /tensorflow_env
ENV PATH="/tensorflow_env/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir tensorflow[and-cuda] scipy matplotlib seaborn \
    scikeras opencv-python

# 6. Usuário e Permissões
RUN useradd -m -u 1000 matlabuser && \
    chown -R matlabuser:matlabuser /ofelio
USER matlabuser

EXPOSE 5901 6080

ENTRYPOINT ["/bin/bash", "-c", "Xvfb :1 -screen 0 1920x1080x24 & sleep 2 && export DISPLAY=:1 && x11vnc -display :1 -nopw -listen localhost -xkb -ncache 10 -forever & matlab -nodesktop -nosplash"]
