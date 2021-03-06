# 动态DNS ddns

配置动态DNS(ddns), 可以让外部通过域名来访问路由器。
一般家庭宽带都是拨号，没有固定IP,外部想通过IP来访问会有困难，通过DDNS将动态的IP绑定到域名


## 前提要求

- 需要公网IP
 
    拨号的动态IP必须是公网IP, 这个如何区分?

    通过路由上网，访问`http://ip.3322.net/`。 这里看到的就是公网IP.

    再打开`https://192.168.1.1` 菜单选择**状态** -> **概况**

    在**网络**下有个`IPv4 WAN 状态`，里面的地址就是路由获取的地址，如果这个地址与公网IP不一样，就是被电信分配了一个内网IP。

    打10000号要求提供公网IP

- 需要一个域名

    如果还没有域名，最好ssh登陆到路由，看`/etc/ddns/services`这个列表，这些是预设的ddns服务商,能使配置ddns变成只要点点点就完成。

    我的域名服务商不在这个列表内,所以只能通过配置脚本来处理。

- 有一个vps更好

    如果宽带没有公网IP,那么有一个vps可以做流量转发，也可以访问路由


## ddns配置

这里只介绍自定义脚本的配置方式，预置服务商的只要多点几次就大概明白了，无需多讲

1. 脚本

    `/root/west.cn.sh` 下载:[west.cn.sh](./west.cn.sh)

    这个脚本在ddns服务定期检测IP发现不同时，通过`send_update()`函数调用

    `send_update()`的实现在`/usr/lib/ddns/dynamic_dns_functions.sh`

    一些看不懂的变量，如`-O $DATFILE -o $ERRFILE` 可以在`/usr/lib/ddns/dynamic_dns_functions.sh`查找到

    脚本中需要修改的是这几行

    ```shell
    __CMDBASE="${__CMDBASE}  --referer 'https://www.west.cn/manager/domain/rsall.asp?domainid=111'" 
    __CMDBASE="${__CMDBASE}  --post-data='act=rsalldomod&did=111&cid=222&val=${__IP}&ttl=900&lng='"
    __CMDBASE="${__CMDBASE}  --header 'Cookie: LoginInfo=5g; ASPSESSIONIDQARCTBAD=OJOGBHG; ASPSESSIONIDSQRRTBAT=JC; ASPSESSIONIDCSBBSQQA=KAO;'"
    ```

    请在`google-chrome`浏览器登陆到域名服务商的域名管理页后，按`F12`调出debug控制台,修改想更新的域名，然后提交。从debug控制台中查看抓包的请求头部的`Referer` , `Cookie` ,及从Post数据中取得请求参数

    `domainid`和`did`的数值是一样的，代表一级域名在域名服务商数据库中的索引。cid代表二级域名的索引。这个在不同服务端中是不一样的。详细还看debug抓包结果


1. 配置ddns入口

    在`/etc/config/ddns`文件后面增加[west.cn.ddns](./west.cn.ddns)内容:

    `cat west.cn.ddns >> /etc/config/ddns `

    `config service '3321'`这里定义的名字3321可以替换成任意有意义的字符
    每个option都是脚本中可以访问的变量，如`$update_script`

    配置里只需要修改域名及脚本:

    ```txt
    option lookup_host 'route.yourdomain.store'
    option update_script '/root/west.cn.sh'
    ```


1. 使配置生效

    在`http://192.168.1.1`菜单选**服务** -> **运态DNS**
  
    找到3321这个配置，后成启用的勾打上，**保存及应用**就可以了。

    如果需要修改配置，也可以在这个主页上操作,而不用再ssh登陆修改`/etc/config/ddns`

1. 如果以上方式无法生效

    [openwrt ddns脚本及配置示例][1] 这个会是你需要的

## ssh遂道

当无公网IP而又需要在外网管理路由，这里需要一个vps,假设其ip及端口为 VPSIP , VPSPORT

1. 创建密钥

    ```shell
    dropbearkey -t rsa -f ${VPSIP}.id_rsa -s 2048
    dropbearkey -t rsa -f ${VPSIP}.id_rsa -y|grep "^ssh-rsa" > ${VPSIP}.id_rsa.pub
    ```

1. 脚本

    将脚本[checkssh.sh](./checkssh.sh) 放到`/root/`目录下

    该脚本检查ssh遂道是否创建，没有的话就创建
    脚本将VPSIP上的20022端口转发到路由本地的22端口，由于VPSIP是公网IP,所以该端口转发使得在外网也可以访问路由

1. 配置定时启动

    在`http://192.168.1.1`菜单选**系统** ->  **计划任务**
    
    **添加** 然后选**自定义***

    任务名和cron参数如下:

    ```txt
    VPS SSH TUN
    */5 * * * * /root/checkssh.sh
    ```

    如图:

    ![CRONJOB_VPS-SSH-TUN.png](./CRONJOB_VPS-SSH-TUN.png)

## 第三重保险

由于域名服务端和dns服务之间的推送未必及时, 可以额外布署脚本定时访问VPS上的nginx服务，然后从日志`/var/run/nginx/access.log`中找到IP

1. 脚本`query.sh`

    ```shell
    echo run $0 > /tmp/hello.tmp
    date >> /tmp/hello.tmp
    /usr/bin/wget 'http://VPSIP/whoami' -a /tmp/hello.tmp
    ```

1. 配置

    如`VPS SSH TUN`一样配置计划任务

    `*/10 * * * * /root/query.sh`

    记得启用，保存及应用

1. 查IP

    登入VPSIP, 输入以下脚本

    `sudo tail -f /var/log/nginx/access.log|grep whoami`

## 参考

[openwrt ddns脚本及配置示例][1]

[1]: https://github.com/openwrt/packages/tree/master/net/ddns-scripts/samples/ "openwrt ddns脚本及配置示例"
