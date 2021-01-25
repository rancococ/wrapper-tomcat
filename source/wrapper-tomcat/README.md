# Java Service Wrapper For Tomcat

## 项目介绍

java service wrapper 3.5.43
   >  - support windows x86-32 and x86-64
   >  - support linux x86-32 and x86-64
   >  - include apr-1.7.0, apr-util-1.6.1, crypto-1.1, expat-1.6.0, ssl-1.1, z-1.2.11, tcnative-1.2.23

## 安装说明

### install for windows:

   | Script name                      | Description                    |
   | -------------------------------- | ------------------------------ |
   | `wrapper-console-start.bat`      | 启动控制     |
   | `wrapper-service-install.bat`    | 安装服务     |
   | `wrapper-service-start.bat`      | 启动服务     |
   | `wrapper-service-stop.bat`       | 停止服务     |
   | `wrapper-service-uninstall.bat`  | 卸载服务     |

### install for linux:

   | Script name                      | Description                    |
   | -------------------------------- | ------------------------------ |
   | `wrapper-console-start.sh`       | 启动控制     |
   | `wrapper-service-install.sh`     | 安装服务     |
   | `wrapper-service-start.sh`       | 启动服务     |
   | `wrapper-service-stop.sh`        | 停止服务     |
   | `wrapper-service-uninstall.sh`   | 卸载服务     |

## 配置说明

   - conf/wrapper-property.conf这个文件里设置服务名称
   - conf/wrapper-additional.conf这个文件里设置内存、端口、其他-D参数
   - conf/wrapper-additional.conf这个文件里的参数如果包含空格，需要使用双引号引起来
   - \#号是注释
   - 配置文件里不能有中文字符，编辑的时候建议用notepad++
