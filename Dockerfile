#
# Base layer for apps using a JVM
#
# This image will contain an Official Oracle version of Java.
#
# Parts of the JRE not required for running server apps are
#   removed to save space.
#
#
FROM alpine:3.8

# The variables below control what style and version of
#   Oracle Java is install
#
# JDL_TYPE can be jdk, jre, or server-jre
#
ENV JDL_TYPE "server-jre"
ENV JDL_VERSION "8"
ENV JDL_UPDATE "172"
ENV JDL_BUILD "11"
ENV JDL_SIG "a58eab1ec242421181065cdc37240b08"
ENV GLIBC_VERSION "2.27-r0"
ENV PROMETHEUS_JMX_AGENT_FILE "/app/jmx/jmx_prometheus_javaagent-0.3.1.jar"

###################################################
#  Use caution adjusting anything below this line #
#    A small change can have a great impact       #
###################################################

#
# Download and Install Oracle Java
#
# Java SE JDK http://download.oracle.com/otn/java/jdk/7u80-b15/jdk-7u80-linux-i586.tar.gz
# Java SE JRE http://download.oracle.com/otn/java/jdk/7u80-b15/jre-7u80-linux-i586.tar.gz
# Server SE JRE http://download.oracle.com/otn-pub/java/jdk/8u92-b14/server-jre-8u92-linux-x64.tar.gz

ENV JAVA_HOME "/usr/lib/jvm/java-${JDL_VERSION}-oracle"

# Download and install Oracle JAVA and OpenSSL
RUN apk --update add \
      bash \
      curl \
      ca-certificates \
      openssl \
      tzdata && \
    cp /usr/share/zoneinfo/America/New_York /etc/localtime && \
    echo "America/New_York" >  /etc/timezone && \
    apk del tzdata && \
    rm -rf /var/cache/apk/* && \
    echo "Download/install GLIBC ${GLIBC_VERSION}" && \
    curl -Ls https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub > /etc/apk/keys/sgerrand.rsa.pub && \
    curl -Ls https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk > /tmp/glibc-${GLIBC_VERSION}.apk && \
    curl -Ls https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk > /tmp/glibc-bin-${GLIBC_VERSION}.apk && \
    apk add /tmp/glibc-${GLIBC_VERSION}.apk /tmp/glibc-bin-${GLIBC_VERSION}.apk && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc/usr/lib && \
    echo "Downloading JAVA" && \
    curl --silent --location --retry 3 \
         --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
         -o /tmp/java.tar.gz \
         http://download.oracle.com/otn-pub/java/jdk/"${JDL_VERSION}"u"${JDL_UPDATE}"-b"${JDL_BUILD}"/"${JDL_SIG}"/jdk-"${JDL_VERSION}"u"${JDL_UPDATE}"-linux-x64.tar.gz && \
    gunzip /tmp/java.tar.gz && \
    tar x -C /tmp/ -f /tmp/java.tar && \
    mkdir -p /usr/lib/jvm && \
    mv /tmp/jdk1.${JDL_VERSION}.0_${JDL_UPDATE} "${JAVA_HOME}" && \
    # Clean-up and slim down the installed files
    apk del curl alpine-sdk perl && \
    rm /var/cache/apk/* \
      /tmp/* && \
    # Update the JVM ttl to 0s (NO internal caching! respect the DNS TTL settings)
    grep -v 'networkaddress.cache.ttl' $JAVA_HOME/jre/lib/security/java.security | grep -v 'networkaddress.cache.negative.ttl' > $JAVA_HOME/jre/lib/security/java.security.tmp && \
    echo 'networkaddress.cache.ttl=0' >> $JAVA_HOME/jre/lib/security/java.security.tmp && \
    echo 'networkaddress.cache.negative.ttl=0' >> $JAVA_HOME/jre/lib/security/java.security.tmp && \
    mv $JAVA_HOME/jre/lib/security/java.security.tmp $JAVA_HOME/jre/lib/security/java.security && \
    # App Service User
    mkdir /app && \
    addgroup app && \
    adduser -G app -s /sbin/nologin -g "App Service Account" -h /app -D app && \
    chown -R app:app /app

ENV LD_LIBRARY_PATH="${JAVA_HOME}/jre/lib/amd64/jli"
ENV PATH="${JAVA_HOME}/bin:$PATH"

COPY jmx /app/jmx/

USER app
WORKDIR /app
