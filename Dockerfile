# Usa una imagen base de Python
FROM python:3.11-slim

# Establece el directorio de trabajo
WORKDIR /app

# Copia los archivos de requerimientos e instala dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia el código de la aplicación
COPY app/ app/

# Expone el puerto que usará el servidor (por ejemplo, Gunicorn en 8000)
EXPOSE 8000

# Comando para iniciar la aplicación (usando Uvicorn para FastAPI)
CMD ["uvicorn", "app.adapters.entrypoints.api:app", "--host", "0.0.0.0", "--port", "8000"]