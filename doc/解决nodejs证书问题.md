# 解决nodejs证书问题

## 背景

错误 “request to https://maas-node.onchain.com/ failed, reason: unable to verify the first cer... errno: 'UNABLE_TO_VERIFY_LEAF_SIGNATURE'”
只要整个证书链任何一个环节验证出现了问题，就会产生该错误。
我们访问的https://maas-node.onchain.com/ 网站本身的证书是不完整的。但通过浏览器访问没有报错是因为浏览器尝试完成了整个证书链（或因为浏览器之前的中级证书缓存，或浏览器主动去下载了中级证书）。浏览器通过当前服务返回的证书去找到上一家给该 server 签名的证书机构（即中级证书）

## 解决方法

### 下载中级证书的.pem文件到nodejs所在环境

https://ssl-tools.net/subjects/49ac5d31600e3d8c2dc3f377e00c67ac69493321

### 设置nodejs的环境变量NODE_EXTRA_CA_CERTS=path\to\certificate.pem

```script
//linux
export NODE_EXTRA_CA_CERTS=/path/to/trusted/CA.pem

//windows powershell
$env:NODE_EXTRA_CA_CERTS = 'D:\Downloads\TrustAsia.pem';
dir env:
```