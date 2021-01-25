# from registry.cn-hangzhou.aliyuncs.com/rancococ/oraclejre:1.8.0_192.6-centos as builder
FROM registry.cn-hangzhou.aliyuncs.com/rancococ/oraclejre:1.8.0_192.6-centos as builder

# maintainer
MAINTAINER "rancococ" <rancococ@qq.com>

# set arg info
ARG jre_version=1.8.192
ARG tomcat_version=8.5.57
ARG wrapper_version=3.5.43.7

# copy script
COPY wrapper-tomcat/ /build/wrapper-tomcat/

# install wrapper-tomcat
RUN sed -i 's/^set.JAVA_HOME/#&/g' "/build/wrapper-tomcat/conf/wrapper.conf"      && \
    \rm -rf /build/wrapper-tomcat/bin/*.bat                                       && \
    \rm -rf /build/wrapper-tomcat/bin/*.exe                                       && \
    \rm -rf /build/wrapper-tomcat/conf/wrapper-property.conf                      && \
    \rm -rf /build/wrapper-tomcat/conf/wrapper-additional.conf                    && \
    \rm -rf /build/wrapper-tomcat/conf/server.xml                                 && \
    \rm -rf /build/wrapper-tomcat/conf/web.xml                                    && \
    \rm -rf /build/wrapper-tomcat/libcore/*.dll                                   && \
    \rm -rf /build/wrapper-tomcat/libextend/*.dll                                 && \
    \rm -rf /build/wrapper-tomcat/tool                                            && \
    touch /build/wrapper-tomcat/bin/version                                       && \
    echo "jre:${jre_version}"         >> /build/wrapper-tomcat/bin/version        && \
    echo "tomcat:${tomcat_version}"   >> /build/wrapper-tomcat/bin/version        && \
    echo "wrapper:${wrapper_version}" >> /build/wrapper-tomcat/bin/version        && \
    find /build/wrapper-tomcat -exec touch {} \;                                  && \
    find /build/wrapper-tomcat -type d -exec chmod 755 {} \;                      && \
    find /build/wrapper-tomcat -type f -exec chmod 644 {} \;                      && \
    find /build/wrapper-tomcat -type f -name ".keep" -exec rm -rf {} \;           && \
    find /build/wrapper-tomcat -type f -name ".gitignore" -exec rm -rf {} \;      && \
    chmod 744 /build/wrapper-tomcat/bin/*                                         && \
    chmod 644 /build/wrapper-tomcat/bin/*.jar                                     && \
    chmod 644 /build/wrapper-tomcat/bin/*.cnf                                     && \
    chmod 644 /build/wrapper-tomcat/bin/version                                   && \
    chmod 600 /build/wrapper-tomcat/conf/*.password                               && \
    chmod 777 /build/wrapper-tomcat/logs                                          && \
    chmod 777 /build/wrapper-tomcat/temp                                          && \
    chown -R app:app /build/wrapper-tomcat                                        && \
    echo "script executed successfully."

# from registry.cn-hangzhou.aliyuncs.com/rancococ/oraclejre:1.8.0_192.6-centos
FROM registry.cn-hangzhou.aliyuncs.com/rancococ/oraclejre:1.8.0_192.6-centos

# copy from builder
COPY --from=builder /build/wrapper-tomcat/ /data/app/

# install wrapper-tomcat
RUN /data/app/bin/wrapper-create-linkfile.sh                                      && \
    \ln -s /data/app/bin/docker-preprocess.sh /docker-preprocess.sh               && \
    chmod +x /docker-preprocess.sh                                                && \
    echo "script executed successfully."

# set work home
WORKDIR /data/app

# expose port
EXPOSE 9404 8080 10087 10001 10002

# stop signal
STOPSIGNAL SIGTERM

# entry point
ENTRYPOINT ["/docker-entrypoint.sh"]

# default command
CMD ["/data/app/bin/wrapper-linux-x86-64", "/data/app/conf/wrapper.conf", "wrapper.syslog.ident=myapp", "wrapper.name=myapp", "wrapper.displayname=myapp", "wrapper.pidfile=/data/app/bin/myapp.pid", "wrapper.statusfile=/data/app/bin/myapp.status", "wrapper.java.pidfile=/data/app/bin/myapp.java.pid", "wrapper.java.idfile=/data/app/bin/myapp.java.id", "wrapper.java.statusfile=/data/app/bin/myapp.java.status", "wrapper.script.version=3.5.43"]
