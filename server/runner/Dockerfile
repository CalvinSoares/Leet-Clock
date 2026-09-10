FROM python:3.13-slim

RUN useradd --uid 65532 --no-create-home --shell /usr/sbin/nologin runner
WORKDIR /runner
COPY entrypoint.py /runner/entrypoint.py
RUN chmod 0555 /runner/entrypoint.py
USER 65532:65532
ENTRYPOINT ["python", "/runner/entrypoint.py"]
