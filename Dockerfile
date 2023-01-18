FROM swift:5.7 as builder

WORKDIR /build
RUN git clone https://github.com/mattpolzin/swift-test-codecov.git

WORKDIR swift-test-codecov
RUN git checkout main \
 && swift build

FROM swift:5.7-slim

COPY --from=builder /build/swift-test-codecov/.build/debug/swift-test-codecov /usr/bin/swift-test-codecov

ENTRYPOINT ["swift-test-codecov"]
