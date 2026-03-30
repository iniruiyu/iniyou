# Multi-stage build for backend services / 后端服务的多阶段构建
FROM --platform=$BUILDPLATFORM golang:1.23-alpine AS build

ARG SERVICE_DIR
ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /src

RUN apk add --no-cache ca-certificates git

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /out/service ./cmd/${SERVICE_DIR}

FROM alpine:3.20

WORKDIR /app
RUN apk add --no-cache ca-certificates nodejs python3
COPY --from=build /usr/local/go /usr/local/go
COPY --from=build /out/service /app/service
ENV PATH="/usr/local/go/bin:${PATH}"

ENTRYPOINT ["/app/service"]
