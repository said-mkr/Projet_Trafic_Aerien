FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt
COPY producer.py /app/producer.py
COPY data_generator.py /app/data_generator.py
CMD ["python", "/app/producer.py"]
