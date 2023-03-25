### 设计
    Root
    Registrar负责注册域名，提供注册域名接口，保存域名失效期限
### problem
- 顶级域名创建的权限只能是owner吗，或者可以有一个地址列表？
- registrar负责创建顶级域名和次级域名
- registrar传入的域名需要参数cost，不然无法得知cost
- setResolver需要不?


### TODO
- 次顶级域名是可以转移的NFT, 那么所有者权限也得跟着NFT的转移而转移, 是否给域名添加租借功能?