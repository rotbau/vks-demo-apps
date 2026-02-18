FROM python:3.15.0a6-alpine3.23

RUN apk add --no-cache curl

RUN pip install flask

COPY app.py /opt/
COPY templates/ /opt/templates/

RUN chown -R 1000:1000 /opt

EXPOSE 8080

WORKDIR /opt

ENTRYPOINT ["python", "app.py"]

USER 1000

CMD ["--color", "blue"]