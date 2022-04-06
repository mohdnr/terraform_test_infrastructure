FROM python:3.9.7-alpine3.14

# Setup app user
RUN addgroup --gid 11111 --system app
RUN adduser --shell /bin/false --uid 11111 --ingroup app --system app

# Install dependencies
COPY consumers/elasticsearch/requirements.txt /tmp/
RUN python -m pip install --upgrade pip
RUN pip3 install --upgrade -r /tmp/requirements.txt
RUN apk add bash

# Add libraries
WORKDIR /app/
COPY queries/queries.json .
COPY consumers/neo4j_connector.py /app/
COPY consumers/elasticsearch/py/elastic_connector.py /app/
COPY consumers/elasticsearch/py/elastic_ingestor.py /app/
RUN chmod +x /app/neo4j_connector.py /app/elastic_connector.py /app/elastic_ingestor.py
RUN mkdir /opt/es-index

# Entrypoint
RUN chown -R app:app /app/ /opt/es-index
USER app
CMD ["python3", "/app/elastic_ingestor.py"]
