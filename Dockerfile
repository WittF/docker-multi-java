# 多阶段构建：从官方Azul Zulu镜像中提取JDK
FROM azul/zulu-openjdk:8-latest as java8
FROM azul/zulu-openjdk:11-latest as java11  
FROM azul/zulu-openjdk:17-latest as java17
FROM azul/zulu-openjdk:21-latest as java21
FROM azul/zulu-openjdk:24-latest as java24

# 最终镜像
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

# 设置时区
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 从官方Azul镜像中复制JDK
COPY --from=java8 /usr/lib/jvm/zulu8 /opt/java/8
COPY --from=java11 /usr/lib/jvm/zulu11 /opt/java/11
COPY --from=java17 /usr/lib/jvm/zulu17 /opt/java/17
COPY --from=java21 /usr/lib/jvm/zulu21 /opt/java/21
COPY --from=java24 /usr/lib/jvm/zulu24 /opt/java/24

# 验证复制的JDK
RUN echo "🔍 验证从官方镜像复制的JDK..." && \
    for v in 8 11 17 21 24; do \
        if [ -d "/opt/java/$v" ]; then \
            echo "检验 Java $v..." && \
            /opt/java/$v/bin/java -version 2>&1 | head -1 && \
            echo "✅ Java $v 正常"; \
        else \
            echo "❌ Java $v 目录不存在"; \
        fi; \
    done

# 创建直接版本命令
RUN for v in 8 11 17 21 24; do \
        if [ -d "/opt/java/$v" ]; then \
            echo "#!/bin/bash" > /usr/local/bin/java$v && \
            echo "exec /opt/java/$v/bin/java \"\$@\"" >> /usr/local/bin/java$v && \
            chmod +x /usr/local/bin/java$v; \
        fi; \
    done

# 创建管理脚本
RUN echo '#!/bin/bash' > /usr/local/bin/java-list && \
    echo 'echo "📦 可用Java版本:"' >> /usr/local/bin/java-list && \
    echo 'for version in 8 11 17 21 24; do' >> /usr/local/bin/java-list && \
    echo '  if [ -d "/opt/java/$version" ]; then' >> /usr/local/bin/java-list && \
    echo '    version_info=$(/opt/java/$version/bin/java -version 2>&1 | head -1 | cut -d"\"" -f2)' >> /usr/local/bin/java-list && \
    echo '    current=$(which java 2>/dev/null | grep -o "/opt/java/[0-9]*" 2>/dev/null || echo "")' >> /usr/local/bin/java-list && \
    echo '    if [ "$current" = "/opt/java/$version" ]; then' >> /usr/local/bin/java-list && \
    echo '      echo "  ✅ Java $version ($version_info) - 当前版本"' >> /usr/local/bin/java-list && \
    echo '    else' >> /usr/local/bin/java-list && \
    echo '      echo "  📦 Java $version ($version_info)"' >> /usr/local/bin/java-list && \
    echo '    fi' >> /usr/local/bin/java-list && \
    echo '  fi' >> /usr/local/bin/java-list && \
    echo 'done' >> /usr/local/bin/java-list && \
    echo 'echo ""; echo "💡 使用: java-change <版本> 或 java<版本> -version"' >> /usr/local/bin/java-list && \
    chmod +x /usr/local/bin/java-list

RUN echo '#!/bin/bash' > /usr/local/bin/java-change && \
    echo 'if [ -z "$1" ]; then echo "用法: java-change {8|11|17|21|24}"; java-list; exit 1; fi' >> /usr/local/bin/java-change && \
    echo 'version="$1"; java_path="/opt/java/$version"' >> /usr/local/bin/java-change && \
    echo 'if [ ! -d "$java_path" ]; then echo "❌ Java $version 未安装"; java-list; exit 1; fi' >> /usr/local/bin/java-change && \
    echo 'echo "export JAVA_HOME=$java_path" > /root/.java_env' >> /usr/local/bin/java-change && \
    echo 'echo "export PATH=$java_path/bin:\$PATH" >> /root/.java_env' >> /usr/local/bin/java-change && \
    echo 'export JAVA_HOME="$java_path"; export PATH="$java_path/bin:$PATH"' >> /usr/local/bin/java-change && \
    echo 'grep -q "source /root/.java_env" /root/.bashrc 2>/dev/null || echo "source /root/.java_env" >> /root/.bashrc' >> /usr/local/bin/java-change && \
    echo 'echo "✅ 已切换到 Java $version"; java -version 2>&1 | head -1' >> /usr/local/bin/java-change && \
    chmod +x /usr/local/bin/java-change

RUN echo '#!/bin/bash' > /usr/local/bin/java-current && \
    echo 'echo "🔍 当前Java配置:"' >> /usr/local/bin/java-current && \
    echo 'echo "JAVA_HOME: ${JAVA_HOME:-未设置}"' >> /usr/local/bin/java-current && \
    echo 'java_cmd=$(which java 2>/dev/null); echo "Java命令: ${java_cmd:-未找到}"' >> /usr/local/bin/java-current && \
    echo 'if [ -n "$java_cmd" ]; then echo ""; echo "🚀 版本信息:"; java -version 2>&1; fi' >> /usr/local/bin/java-current && \
    echo 'echo ""; echo "💡 java-list 查看版本 | java-change <版本> 切换"' >> /usr/local/bin/java-current && \
    chmod +x /usr/local/bin/java-current

# 设置默认Java版本 (Java 17)
RUN echo "export JAVA_HOME=/opt/java/17" > /root/.java_env && \
    echo "export PATH=/opt/java/17/bin:\$PATH" >> /root/.java_env && \
    echo "echo '🚀 Multi-Java 镜像已就绪 (默认: Java 17)'" >> /root/.bashrc && \
    echo "echo '💡 java-list 查看版本 | java-change <版本> 切换版本'" >> /root/.bashrc && \
    echo "source /root/.java_env" >> /root/.bashrc

# 设置默认环境变量
ENV JAVA_HOME=/opt/java/17
ENV PATH=/opt/java/17/bin:$PATH

WORKDIR /app
CMD ["bash"]