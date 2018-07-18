#
# Base layer for apps using a JVM
#
FROM openjdk:8u171-jre-slim

ENV PROMETHEUS_JMX_AGENT_FILE "/app/jmx/jmx_prometheus_javaagent-0.3.1.jar"

# JVM Settings for JAR apps used by a majority of the apps
ENV CL_DEFAULT_JVM -javaagent:${PROMETHEUS_JMX_AGENT_FILE}=9001:/app/jmx/config.yaml \
 -XX:+UnlockExperimentalVMOptions \
 -XX:+UseCGroupMemoryLimitForHeap \
 -XX:MaxRAMFraction=2 \
 -XshowSettings:vm \
 -XX:+ExitOnOutOfMemoryError \
 -server

# JVM Settings for Play apps used by a majority of the apps
ENV CL_DEFAULT_PLAY -J-javaagent:${PROMETHEUS_JMX_AGENT_FILE}=9001:/app/jmx/config.yaml \
 -J-XX:+UnlockExperimentalVMOptions \
 -J-XX:+UseCGroupMemoryLimitForHeap \
 -J-XX:MaxRAMFraction=2 \
 -J-XshowSettings:vm \
 -J-XX:+ExitOnOutOfMemoryError \
 -J-server

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    # Add curl
    apt-get update && apt-get install -y --no-install-recommends \
      curl \
      && rm -rf /var/lib/apt/lists/* && \
    # Update the JVM ttl to 0s (NO internal caching! respect the DNS TTL settings)
    grep -v 'networkaddress.cache.ttl' /etc/java-8-openjdk/security/java.security | grep -v 'networkaddress.cache.negative.ttl' > /etc/java-8-openjdk/security/java.security.tmp && \
      echo 'networkaddress.cache.ttl=0' >> /etc/java-8-openjdk/security/java.security.tmp && \
      echo 'networkaddress.cache.negative.ttl=0' >> /etc/java-8-openjdk/security/java.security.tmp && \
      mv /etc/java-8-openjdk/security/java.security.tmp /etc/java-8-openjdk/security/java.security && \
    # App Service User
    adduser --gecos "App Service Account" --shell /usr/sbin/nologin --disabled-login --home /app app && rm -f /app/.bash_logout /app/.bashrc /app/.profile

COPY jmx /app/jmx/

USER app
WORKDIR /app
