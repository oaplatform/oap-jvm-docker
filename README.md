# oap-jvm-docker

Parent docker image from [Debian Slim](https://hub.docker.com/_/debian/tags?page=2) with preinstalled JDK and basic tools for work in containers

## mongo-shell

Installing mongo-shell can be enabled

## Affinity optimization

libjna-java tool preinstalled for enabling [Java Thread Affinity](https://github.com/OpenHFT/Java-Thread-Affinity) optimization

## Build

Image tag: `<oap.docker.repository>/<oap.docker.image>:<corretto>-<version>`, e.g. `oap.xenoss.net/oap-jvm:25.0.5.1.2-6`.

* `version`, `oap.jvm.version` (JDK major) — `gradle.properties`
* `<corretto>` — latest `java-<oap.jvm.version>-amazon-corretto-jdk` from apt.corretto.aws available for all platforms;
  pin with `-Poap.corretto.package.version=1:25.0.5.1.2-1`
* env `REPOSITORY_URL` overrides `oap.docker.repository`
* the tag is printed as TeamCity build number (`##teamcity[buildNumber '...']`)

```shell
./gradlew dockerBuild   # build multi-arch image (linux/arm64,linux/amd64)
./gradlew dockerPush    # build and push

# single platform
./gradlew dockerBuild -Poap.docker.platforms=linux/amd64
```
