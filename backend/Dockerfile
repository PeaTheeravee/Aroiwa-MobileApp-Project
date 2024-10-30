# Use an official Python runtime as a parent image
FROM python:3.12-slim

COPY . .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir --upgrade -r ./requirements.txt
RUN pip install poetry
RUN poetry install