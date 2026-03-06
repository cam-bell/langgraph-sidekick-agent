FROM python:3.12-slim

# System deps needed by Chromium on Debian slim
RUN apt-get update && apt-get install -y \
    curl wget gnupg ca-certificates \
    libnss3 libatk-bridge2.0-0 libgtk-3-0 libx11-xcb1 libxcomposite1 libxdamage1 libxrandr2 \
    libasound2 libxshmfence1 libgbm1 libxkbcommon0 \
    libxfixes3 libxext6 libxrender1 libxi6 libxss1 libxtst6 \
    libcups2 libdrm2 libdbus-1-3 libatspi2.0-0 \
    fonts-liberation fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /sidekick
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright browser binaries (OS deps already installed above)
RUN python -m playwright install chromium

COPY . .
EXPOSE 7860

# HF Spaces expects the server on 0.0.0.0:7860
CMD ["python", "app.py"]