FROM bitnami/python
RUN apt-get update
RUN pip install oscar_python
RUN pip install liboidcagent

RUN mkdir -p /app/acc-services/
COPY acc.py /app/acc-services/
COPY script.sh /app/acc-services/

