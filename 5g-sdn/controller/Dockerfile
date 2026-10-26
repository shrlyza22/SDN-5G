FROM python:3.9-slim
RUN pip install --no-cache-dir "setuptools<66" wheel \
 && pip install --no-cache-dir ryu==4.34 eventlet==0.30.2
WORKDIR /app
EXPOSE 6653
