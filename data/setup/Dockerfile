FROM python:3.7-slim-buster

WORKDIR /app/setup

COPY requirements.txt requirements.txt

RUN pip3 install -r requirements.txt

CMD [ "python3", "process.py" ]
# ENTRYPOINT ["tail", "-f", "/dev/null"]