# Usa un'immagine base di Debian
FROM debian:latest

# Imposta il maintainer del progetto
LABEL maintainer="tuo_nome@example.com"

# Aggiorna il sistema e installa i pacchetti necessari
RUN apt-get update && apt-get install -y \
    build-essential \
    flex \
    bison \
    clang \
    wget \
    lsb-release \
    software-properties-common

# Aggiungi i repository per LLVM 17
RUN wget https://apt.llvm.org/llvm.sh \
    && chmod +x llvm.sh \
    && ./llvm.sh 17 all


# Installa LLVM 17
RUN apt-get install -y llvm-17 clang-17 lldb-17 lld-17

# Crea una directory di lavoro
WORKDIR /app

# Copia i file del progetto nella directory di lavoro
COPY . .

# Comando per compilare il progetto (modifica questo comando in base alle tue esigenze di compilazione)
RUN make

# Comando di default quando il container viene avviato
CMD ["bash"]
