# AGENTS.md

Base docker image (Debian slim + Amazon Corretto JDK), built with Gradle Kotlin DSL.

## Versioning

- Every change must increment `version` in `gradle.properties` by 1 (e.g. `6` → `7`).
- `version` is a plain integer; one bump per change, never decrease it.
- Do not encode the JDK version in `version`: the JDK major is `oap.jvm.version`,
  the Corretto patch level is resolved automatically from apt.corretto.aws.
- The PR `Version Check` workflow fails if `version` was not bumped.

## Build

- Image tag: `<oap.docker.repository>/<oap.docker.image>:<corretto>-<version>`, e.g. `oap.xenoss.net/oap-jvm:25.0.5.1.2-7`.
- `./gradlew dockerBuild` — build (single platform: `-Poap.docker.platforms=linux/amd64`).
- `./gradlew dockerPush` — build and push to the registry; run only when explicitly asked.

## Git

- Commit directly on `master`, no feature branches.
