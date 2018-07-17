#
# Base layer for apps using a JVM
#
FROM openjdk:8u171-jre-slim

ENV PROMETHEUS_JMX_AGENT_FILE "/app/jmx/jmx_prometheus_javaagent-0.3.1.jar"

ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
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
