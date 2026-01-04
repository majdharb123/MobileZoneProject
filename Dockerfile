# =========================
# 1️⃣ Base image
# =========================
FROM ubuntu:22.04

# =========================
# 2️⃣ System dependencies
# =========================
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa wget \
    nodejs npm \
    && apt-get clean

# =========================
# 3️⃣ Install Flutter
# =========================
RUN git clone https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH"

RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --enable-web

# =========================
# 4️⃣ Build Flutter Web
# =========================
WORKDIR /app/test
COPY test/ .

RUN flutter pub get
RUN flutter build web

# =========================
# 5️⃣ Backend setup
# =========================
WORKDIR /app/backend
COPY backend/ .

RUN npm install

# =========================
# 6️⃣ Expose backend port
# =========================
EXPOSE 10000

# =========================
# 7️⃣ Start Node.js server
# =========================
CMD ["node", "server.js"]