FROM swift:latest as builder

WORKDIR /build
RUN git clone https://github.com/mattpolzin/swift-test-codecov.git

WORKDIR swift-test-codecov
RUN git checkout master \
 && swift build

FROM swift:latest

COPY --from=builder /build/swift-test-codecov/.build/debug/swift-test-codecov /swift-test-codecov

ENTRYPOINT ["/swift-test-codecov"]
