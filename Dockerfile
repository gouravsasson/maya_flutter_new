FROM cirrusci/flutter:stable

WORKDIR /app

COPY . .

RUN flutter pub get

CMD ["flutter", "build", "apk", "--release"]
