FROM python:3.12-slim
WORKDIR /app
COPY index.html .
CMD ["python3", "-m", "http.server", "8000", "--bind", "0.0.0.0"]
