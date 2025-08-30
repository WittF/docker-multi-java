# Multi-Java Docker 镜像

包含多版本Java的Docker镜像，开箱即用。

## 📦 版本
Java 8, 11, 17, 21, 24 (Azul Zulu JDK)，默认Java 17

使用官方 `azul/zulu-openjdk:*-latest` 镜像作为源

## 🔧 命令
- `java` - 默认版本
- `java8`, `java11`, `java17`, `java21`, `java24` - 直接使用特定版本  
- `java-change <版本>` - 切换默认版本
- `java-list` - 显示所有版本
  - `java-current` - 显示当前配置详情

**镜像发布地址:**
- GitHub Container Registry: `ghcr.io/wittf/multi-java:latest`
- Docker Hub: `wittf/multi-java:latest`
